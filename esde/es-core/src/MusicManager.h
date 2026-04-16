//  SPDX-License-Identifier: MIT
//
//  ES-DE Frontend
//  MusicManager.h
//
//  Background music playback for the frontend.
//

#ifndef ES_CORE_MUSIC_MANAGER_H
#define ES_CORE_MUSIC_MANAGER_H

extern "C" {
#include <libavcodec/avcodec.h>
#include <libavformat/avformat.h>
#include <libavutil/channel_layout.h>
#include <libavutil/samplefmt.h>
#include <libswresample/swresample.h>
}

#include <atomic>
#include <memory>
#include <random>
#include <string>
#include <thread>
#include <vector>

class MusicManager
{
public:
    ~MusicManager();
    static MusicManager& getInstance();

    void init();
    void deinit();
    void update(int deltaTime);

    void pause();
    void resume();

    bool nextTrack();
    bool previousTrack();

private:
    MusicManager() noexcept;

    bool isPlaybackEnabled() const;
    void refreshTracks(bool force = false);
    bool startTrack(bool showPopup);
    bool skipTrack(int direction);
    void syncPlaylistPositionToCurrentTrack();
    void advanceTrackPosition(int direction);
    void rebuildPlaylist(const std::string& currentTrack = "");
    void stopDecoder(bool clearStream, bool clearCurrentTrack);
    void resetDecoder();
    bool openTrack(const std::string& path);
    void decodeTrack();
    bool outputFrame();
    bool isSupportedFile(const std::string& path) const;
    void queueNowPlayingPopup() const;

    std::vector<std::string> mTracks;
    std::vector<size_t> mPlaylist;
    std::unique_ptr<std::thread> mDecoderThread;
    std::mt19937 mRandomEngine;

    AVFormatContext* mFormatContext;
    AVCodecContext* mCodecContext;
    AVCodec* mCodec;
    AVPacket* mPacket;
    AVFrame* mFrame;
    SwrContext* mResampler;

    std::string mCurrentTrack;
    int mAudioStreamIndex;
    int mPlaylistPosition;
    int mTrackScanAccumulator;
    bool mInitialized;

    std::atomic<bool> mStopDecoder;
    std::atomic<bool> mDecoderFinished;
    std::atomic<bool> mPaused;
};

#endif // ES_CORE_MUSIC_MANAGER_H
