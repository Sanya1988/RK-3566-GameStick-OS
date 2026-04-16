//  SPDX-License-Identifier: MIT
//
//  ES-DE Frontend
//  MusicManager.cpp
//
//  Background music playback for the frontend.
//

#include "MusicManager.h"

#include "AudioManager.h"
#include "Log.h"
#include "Settings.h"
#include "Window.h"
#include "utils/FileSystemUtil.h"
#include "utils/LocalizationUtil.h"
#include "utils/StringUtil.h"

#include <SDL2/SDL.h>

#include <algorithm>
#include <array>
#include <numeric>

#if LIBAVUTIL_VERSION_MAJOR >= 58 ||                                                               \
    (LIBAVUTIL_VERSION_MAJOR >= 57 && LIBAVUTIL_VERSION_MINOR >= 28)
#define CHANNELS ch_layout.nb_channels
#else
#define CHANNELS channels
#endif

namespace
{
    constexpr int TRACK_SCAN_INTERVAL {5000};
    constexpr int MUSIC_BUFFER_LIMIT_BYTES {2 * 1024 * 1024};

    std::string resolveMusicDirectory()
    {
        const std::string configuredDirectory {
            Settings::getInstance()->getString("BackgroundMusicDirectory")};

        if (Utils::FileSystem::isDirectory(configuredDirectory))
            return configuredDirectory;

        const std::array<std::string, 2> fallbackDirectories {"/storage/music",
                                                              "/userdata/music"};

        for (const auto& directory : fallbackDirectories) {
            if (directory != configuredDirectory && Utils::FileSystem::isDirectory(directory))
                return directory;
        }

        return configuredDirectory;
    }
} // namespace

MusicManager::MusicManager() noexcept
    : mDecoderThread {nullptr}
    , mRandomEngine {std::random_device {}()}
    , mFormatContext {nullptr}
    , mCodecContext {nullptr}
    , mCodec {nullptr}
    , mPacket {nullptr}
    , mFrame {nullptr}
    , mResampler {nullptr}
    , mAudioStreamIndex {-1}
    , mPlaylistPosition {0}
    , mTrackScanAccumulator {TRACK_SCAN_INTERVAL}
    , mInitialized {false}
    , mStopDecoder {false}
    , mDecoderFinished {false}
    , mPaused {false}
{
}

MusicManager::~MusicManager() { deinit(); }

MusicManager& MusicManager::getInstance()
{
    static MusicManager instance;
    return instance;
}

void MusicManager::init()
{
    if (mInitialized)
        return;

    mInitialized = true;
    mPaused = false;
    mTrackScanAccumulator = TRACK_SCAN_INTERVAL;
    refreshTracks(true);
}

void MusicManager::deinit()
{
    if (!mInitialized)
        return;

    stopDecoder(true, true);
    mTracks.clear();
    mPlaylist.clear();
    mInitialized = false;
    mPaused = false;
}

void MusicManager::update(int deltaTime)
{
    if (!mInitialized)
        return;

    if (!isPlaybackEnabled()) {
        stopDecoder(true, false);
        return;
    }

    if (deltaTime > 0)
        mTrackScanAccumulator += deltaTime;

    refreshTracks(false);

    if (mTracks.empty())
        return;

    if (mPaused)
        return;

    if (!mCurrentTrack.empty() && !Utils::FileSystem::exists(mCurrentTrack)) {
        refreshTracks(true);
        if (mTracks.empty())
            return;
    }

    if (mDecoderFinished && AudioManager::getInstance().getPendingMusicBytes() == 0) {
        advanceTrackPosition(1);
        startTrack(true);
        return;
    }

    if (!mDecoderThread)
        startTrack(mCurrentTrack.empty());
}

void MusicManager::pause()
{
    if (!mInitialized || mPaused)
        return;

    mPaused = true;
    AudioManager::getInstance().clearMusicStream();
}

void MusicManager::resume()
{
    if (!mInitialized)
        return;

    if (!isPlaybackEnabled()) {
        stopDecoder(true, false);
        return;
    }

    mPaused = false;
    refreshTracks(true);

    if (mTracks.empty())
        return;

    if (!mDecoderThread)
        startTrack(false);
}

bool MusicManager::nextTrack()
{
    return skipTrack(1);
}

bool MusicManager::previousTrack()
{
    return skipTrack(-1);
}

bool MusicManager::isPlaybackEnabled() const
{
    return AudioManager::getInstance().getHasAudioDevice() &&
           Settings::getInstance()->getBool("BackgroundMusic");
}

void MusicManager::refreshTracks(const bool force)
{
    if (!force && mTrackScanAccumulator < TRACK_SCAN_INTERVAL)
        return;

    mTrackScanAccumulator = 0;

    const std::string configuredDirectory {
        Settings::getInstance()->getString("BackgroundMusicDirectory")};
    const std::string musicDirectory {resolveMusicDirectory()};
    std::vector<std::string> tracks;

    if (force && musicDirectory != configuredDirectory) {
        LOG(LogInfo) << "MusicManager: Background music directory \"" << configuredDirectory
                     << "\" is unavailable, falling back to \"" << musicDirectory << "\"";
    }

    if (Utils::FileSystem::isDirectory(musicDirectory)) {
        for (const auto& entry : Utils::FileSystem::getDirContent(musicDirectory, true)) {
            if (!Utils::FileSystem::isRegularFile(entry))
                continue;
            if (!isSupportedFile(entry))
                continue;
            tracks.emplace_back(entry);
        }
    }

    std::sort(tracks.begin(), tracks.end());

    if (tracks == mTracks) {
        if (force && mTracks.empty()) {
            if (!Utils::FileSystem::isDirectory(musicDirectory)) {
                LOG(LogWarning) << "MusicManager: Background music directory \""
                                << musicDirectory << "\" does not exist";
            }
            else {
                LOG(LogInfo) << "MusicManager: No supported background music files found in \""
                             << musicDirectory << "\"";
            }
        }
        return;
    }

    const std::string previousTrack {mCurrentTrack};
    mTracks = tracks;
    rebuildPlaylist(previousTrack);

    if (mTracks.empty()) {
        if (!Utils::FileSystem::isDirectory(musicDirectory)) {
            LOG(LogWarning) << "MusicManager: Background music directory \"" << musicDirectory
                            << "\" does not exist";
        }
        else {
            LOG(LogInfo) << "MusicManager: No supported background music files found in \""
                         << musicDirectory << "\"";
        }
        stopDecoder(true, true);
    }
    else {
        LOG(LogInfo) << "MusicManager: Found " << mTracks.size()
                     << " background music file(s) in \"" << musicDirectory << "\"";
    }
}

bool MusicManager::startTrack(const bool showPopup)
{
    if (mTracks.empty() || mPaused || !isPlaybackEnabled())
        return false;

    stopDecoder(true, false);

    if (mPlaylist.empty())
        rebuildPlaylist(mCurrentTrack);

    if (mPlaylist.empty())
        return false;

    for (size_t attempts {0}; attempts < mPlaylist.size(); ++attempts) {
        const std::string& candidate {mTracks.at(mPlaylist.at(mPlaylistPosition))};

        if (openTrack(candidate)) {
            mCurrentTrack = candidate;
            mStopDecoder = false;
            mDecoderFinished = false;
            mDecoderThread = std::make_unique<std::thread>(&MusicManager::decodeTrack, this);

            LOG(LogInfo) << "MusicManager: Playing background track \"" << mCurrentTrack << "\"";
            if (showPopup)
                queueNowPlayingPopup();

            return true;
        }

        advanceTrackPosition(1);
    }

    stopDecoder(true, true);
    return false;
}

void MusicManager::advanceTrackPosition(const int direction)
{
    if (mTracks.empty())
        return;

    if (mPlaylist.empty())
        rebuildPlaylist(mCurrentTrack);

    if (mPlaylist.empty())
        return;

    if (direction > 0) {
        ++mPlaylistPosition;
        if (mPlaylistPosition >= static_cast<int>(mPlaylist.size())) {
            rebuildPlaylist();
            mPlaylistPosition = 0;
        }
    }
    else if (direction < 0) {
        --mPlaylistPosition;
        if (mPlaylistPosition < 0)
            mPlaylistPosition = static_cast<int>(mPlaylist.size()) - 1;
    }
}

bool MusicManager::skipTrack(const int direction)
{
    if (!isPlaybackEnabled())
        return false;

    refreshTracks(true);
    if (mTracks.empty())
        return false;

    if (mPlaylist.empty())
        rebuildPlaylist(mCurrentTrack);

    if (mPlaylist.empty())
        return false;

    syncPlaylistPositionToCurrentTrack();

    const std::string currentTrack {mCurrentTrack};

    if (mPlaylist.size() > 1) {
        for (size_t attempts {0}; attempts < mPlaylist.size(); ++attempts) {
            advanceTrackPosition(direction);

            if (mTracks.at(mPlaylist.at(mPlaylistPosition)) != currentTrack)
                return startTrack(true);
        }

        return false;
    }

    return startTrack(true);
}

void MusicManager::syncPlaylistPositionToCurrentTrack()
{
    if (mTracks.empty() || mPlaylist.empty() || mCurrentTrack.empty())
        return;

    const auto currentTrackIt {std::find(mTracks.cbegin(), mTracks.cend(), mCurrentTrack)};
    if (currentTrackIt == mTracks.cend())
        return;

    const size_t currentIndex {static_cast<size_t>(
        std::distance(mTracks.cbegin(), currentTrackIt))};
    const auto playlistIt {std::find(mPlaylist.cbegin(), mPlaylist.cend(), currentIndex)};

    if (playlistIt != mPlaylist.cend())
        mPlaylistPosition = static_cast<int>(std::distance(mPlaylist.cbegin(), playlistIt));
}

void MusicManager::rebuildPlaylist(const std::string& currentTrack)
{
    mPlaylist.clear();

    if (mTracks.empty()) {
        mPlaylistPosition = 0;
        if (!currentTrack.empty())
            mCurrentTrack.clear();
        return;
    }

    mPlaylist.resize(mTracks.size());
    std::iota(mPlaylist.begin(), mPlaylist.end(), 0);
    std::shuffle(mPlaylist.begin(), mPlaylist.end(), mRandomEngine);

    mPlaylistPosition = 0;

    if (!currentTrack.empty()) {
        const auto currentIt {std::find(mTracks.cbegin(), mTracks.cend(), currentTrack)};
        if (currentIt != mTracks.cend()) {
            const size_t currentIndex {
                static_cast<size_t>(std::distance(mTracks.cbegin(), currentIt))};
            const auto playlistIt {std::find(mPlaylist.begin(), mPlaylist.end(), currentIndex)};
            if (playlistIt != mPlaylist.end()) {
                std::iter_swap(mPlaylist.begin(), playlistIt);
                mPlaylistPosition = 0;
                return;
            }
        }

        mCurrentTrack.clear();
    }
}

void MusicManager::stopDecoder(const bool clearStream, const bool clearCurrentTrack)
{
    mStopDecoder = true;

    if (mDecoderThread) {
        if (mDecoderThread->joinable())
            mDecoderThread->join();
        mDecoderThread.reset();
    }

    resetDecoder();
    mDecoderFinished = false;

    if (clearStream)
        AudioManager::getInstance().clearMusicStream();

    if (clearCurrentTrack)
        mCurrentTrack.clear();
}

void MusicManager::resetDecoder()
{
    if (mPacket != nullptr)
        av_packet_free(&mPacket);
    if (mFrame != nullptr)
        av_frame_free(&mFrame);
    if (mCodecContext != nullptr)
        avcodec_free_context(&mCodecContext);
    if (mFormatContext != nullptr)
        avformat_close_input(&mFormatContext);
    if (mResampler != nullptr)
        swr_free(&mResampler);

    mPacket = nullptr;
    mFrame = nullptr;
    mCodecContext = nullptr;
    mFormatContext = nullptr;
    mResampler = nullptr;
    mCodec = nullptr;
    mAudioStreamIndex = -1;
}

bool MusicManager::openTrack(const std::string& path)
{
    resetDecoder();

    mFormatContext = avformat_alloc_context();
    if (mFormatContext == nullptr) {
        LOG(LogError) << "MusicManager::openTrack(): Couldn't allocate format context";
        return false;
    }

    if (avformat_open_input(&mFormatContext, path.c_str(), nullptr, nullptr) != 0) {
        LOG(LogError) << "MusicManager::openTrack(): Couldn't open \"" << path << "\"";
        resetDecoder();
        return false;
    }

    if (avformat_find_stream_info(mFormatContext, nullptr) < 0) {
        LOG(LogError) << "MusicManager::openTrack(): Couldn't read stream info for \"" << path
                      << "\"";
        resetDecoder();
        return false;
    }

    mAudioStreamIndex = av_find_best_stream(mFormatContext, AVMEDIA_TYPE_AUDIO, -1, -1, nullptr, 0);

    if (mAudioStreamIndex < 0) {
        LOG(LogError) << "MusicManager::openTrack(): No audio stream found in \"" << path << "\"";
        resetDecoder();
        return false;
    }

    mCodec = const_cast<AVCodec*>(
        avcodec_find_decoder(mFormatContext->streams[mAudioStreamIndex]->codecpar->codec_id));

    if (mCodec == nullptr) {
        LOG(LogError) << "MusicManager::openTrack(): Couldn't find decoder for \"" << path << "\"";
        resetDecoder();
        return false;
    }

    mCodecContext = avcodec_alloc_context3(mCodec);
    if (mCodecContext == nullptr) {
        LOG(LogError) << "MusicManager::openTrack(): Couldn't allocate codec context for \"" << path
                      << "\"";
        resetDecoder();
        return false;
    }

    if (avcodec_parameters_to_context(mCodecContext,
                                      mFormatContext->streams[mAudioStreamIndex]->codecpar) != 0) {
        LOG(LogError) << "MusicManager::openTrack(): Couldn't copy codec parameters for \"" << path
                      << "\"";
        resetDecoder();
        return false;
    }

    if (avcodec_open2(mCodecContext, mCodec, nullptr) != 0) {
        LOG(LogError) << "MusicManager::openTrack(): Couldn't open decoder for \"" << path << "\"";
        resetDecoder();
        return false;
    }

    mPacket = av_packet_alloc();
    mFrame = av_frame_alloc();

    if (mPacket == nullptr || mFrame == nullptr) {
        LOG(LogError) << "MusicManager::openTrack(): Couldn't allocate decode buffers for \""
                      << path << "\"";
        resetDecoder();
        return false;
    }

#if LIBAVUTIL_VERSION_MAJOR >= 58 ||                                                               \
    (LIBAVUTIL_VERSION_MAJOR >= 57 && LIBAVUTIL_VERSION_MINOR >= 28)
    AVChannelLayout destinationLayout {};
    av_channel_layout_default(&destinationLayout, 2);
    int resamplerResult {swr_alloc_set_opts2(&mResampler, &destinationLayout, AV_SAMPLE_FMT_FLT,
                                             mCodecContext->sample_rate, &mCodecContext->ch_layout,
                                             mCodecContext->sample_fmt,
                                             mCodecContext->sample_rate, 0, nullptr)};
    av_channel_layout_uninit(&destinationLayout);
    if (resamplerResult >= 0 && mResampler != nullptr)
        resamplerResult = swr_init(mResampler);
#else
    mResampler = swr_alloc_set_opts(
        nullptr, AV_CH_LAYOUT_STEREO, AV_SAMPLE_FMT_FLT, mCodecContext->sample_rate,
        av_get_default_channel_layout(mCodecContext->CHANNELS), mCodecContext->sample_fmt,
        mCodecContext->sample_rate, 0, nullptr);
    const int resamplerResult {mResampler == nullptr ? AVERROR(ENOMEM) : swr_init(mResampler)};
#endif

    if (mResampler == nullptr || resamplerResult < 0) {
        LOG(LogError) << "MusicManager::openTrack(): Couldn't initialize resampler for \"" << path
                      << "\"";
        resetDecoder();
        return false;
    }

    AudioManager::getInstance().setupMusicStream(mCodecContext->sample_rate);
    return true;
}

void MusicManager::decodeTrack()
{
    bool flushedDecoder {false};

    while (!mStopDecoder) {
        if (mPaused) {
            SDL_Delay(50);
            continue;
        }

        if (!AudioManager::getInstance().getHasAudioDevice()) {
            SDL_Delay(100);
            continue;
        }

        if (AudioManager::getInstance().getPendingMusicBytes() > MUSIC_BUFFER_LIMIT_BYTES) {
            SDL_Delay(20);
            continue;
        }

        const int readResult {av_read_frame(mFormatContext, mPacket)};

        if (readResult >= 0) {
            if (mPacket->stream_index == mAudioStreamIndex) {
                int sendResult {avcodec_send_packet(mCodecContext, mPacket)};
                while (!mStopDecoder && sendResult == AVERROR(EAGAIN)) {
                    if (!outputFrame())
                        break;
                    sendResult = avcodec_send_packet(mCodecContext, mPacket);
                }

                if (sendResult == 0) {
                    while (!mStopDecoder && outputFrame()) {}
                }
                else if (sendResult < 0 && sendResult != AVERROR(EAGAIN)) {
                    LOG(LogError) << "MusicManager::decodeTrack(): Couldn't submit audio packet";
                }
            }

            av_packet_unref(mPacket);
            continue;
        }

        if (!flushedDecoder) {
            avcodec_send_packet(mCodecContext, nullptr);
            while (!mStopDecoder && outputFrame()) {}
            flushedDecoder = true;
        }

        break;
    }

    av_packet_unref(mPacket);
    mDecoderFinished = !mStopDecoder;
}

bool MusicManager::outputFrame()
{
    const int receiveResult {avcodec_receive_frame(mCodecContext, mFrame)};

    if (receiveResult == AVERROR(EAGAIN) || receiveResult == AVERROR_EOF)
        return false;

    if (receiveResult < 0) {
        LOG(LogError) << "MusicManager::outputFrame(): Couldn't decode audio frame";
        return false;
    }

    const int outputSamples {static_cast<int>(av_rescale_rnd(
        swr_get_delay(mResampler, mCodecContext->sample_rate) + mFrame->nb_samples,
        mCodecContext->sample_rate, mCodecContext->sample_rate, AV_ROUND_UP))};
    const int outputBufferSize {
        av_samples_get_buffer_size(nullptr, 2, outputSamples, AV_SAMPLE_FMT_FLT, 0)};

    if (outputBufferSize <= 0) {
        av_frame_unref(mFrame);
        return false;
    }

    std::vector<uint8_t> converted(static_cast<size_t>(outputBufferSize));
    uint8_t* outputData[1] {converted.data()};

    const int convertedSamples {swr_convert(mResampler, outputData, outputSamples,
                                            const_cast<const uint8_t**>(mFrame->extended_data),
                                            mFrame->nb_samples)};

    av_frame_unref(mFrame);

    if (convertedSamples < 0) {
        LOG(LogError) << "MusicManager::outputFrame(): Couldn't resample audio frame";
        return false;
    }

    if (convertedSamples == 0)
        return false;

    const int convertedSize {
        av_samples_get_buffer_size(nullptr, 2, convertedSamples, AV_SAMPLE_FMT_FLT, 0)};

    if (convertedSize > 0)
        AudioManager::getInstance().processMusicStream(converted.data(), convertedSize);

    return true;
}

bool MusicManager::isSupportedFile(const std::string& path) const
{
    static const std::vector<std::string> extensions {".aac", ".flac", ".m4a", ".mp3",
                                                      ".ogg", ".opus", ".wav"};
    const std::string extension {Utils::String::toLower(Utils::FileSystem::getExtension(path))};
    return std::find(extensions.cbegin(), extensions.cend(), extension) != extensions.cend();
}

void MusicManager::queueNowPlayingPopup() const
{
    if (mCurrentTrack.empty())
        return;

    Window::getInstance()->queueInfoPopup(
        Utils::String::format(
            _("NOW PLAYING '%s'"),
            Utils::String::toUpper(Utils::FileSystem::getStem(mCurrentTrack)).c_str()),
        4000);
}
