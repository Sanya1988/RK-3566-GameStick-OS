//  SPDX-License-Identifier: MIT
//
//  ES-DE Frontend
//  GuiMetaDataEd.h
//
//  Game metadata edit user interface.
//  This interface is triggered from the GuiGamelistOptions menu.
//  The scraping interface is handled by GuiScraperSingle which calls GuiScraperSearch.
//

#ifndef ES_APP_GUIS_GUI_META_DATA_ED_H
#define ES_APP_GUIS_GUI_META_DATA_ED_H

#include "GuiComponent.h"
#include "MetaData.h"
#include "components/BackgroundComponent.h"
#include "components/BadgeComponent.h"
#include "components/ComponentGrid.h"
#include "components/ScrollIndicatorComponent.h"
#include "guis/GuiSettings.h"
#if !defined(GAMESTICK_OFFLINE)
#include "scrapers/Scraper.h"
#endif
#include "views/ViewController.h"

class ComponentList;
class FileData;
class SystemData;
class TextComponent;

class GuiMetaDataEd : public GuiComponent
{
public:
#if defined(GAMESTICK_OFFLINE)
    GuiMetaDataEd(MetaDataList* md,
                  const std::vector<MetaDataDecl>& mdd,
                  FileData* game,
                  SystemData* system,
                  std::function<void()> savedCallback,
                  std::function<void()> clearGameFunc,
                  std::function<void()> deleteGameFunc);
#else
    GuiMetaDataEd(MetaDataList* md,
                  const std::vector<MetaDataDecl>& mdd,
                  const ScraperSearchParams params,
                  std::function<void()> savedCallback,
                  std::function<void()> clearGameFunc,
                  std::function<void()> deleteGameFunc);
#endif

    bool input(InputConfig* config, Input input) override;
    void onSizeChanged() override;

    std::vector<HelpPrompt> getHelpPrompts() override;

private:
    void save();
#if !defined(GAMESTICK_OFFLINE)
    void fetch();
    void fetchDone(const ScraperSearchResult& result);
#endif
    void close();

    Renderer* mRenderer;
    BackgroundComponent mBackground;
    ComponentGrid mGrid;

    std::shared_ptr<TextComponent> mTitle;
    std::shared_ptr<ImageComponent> mScrollUp;
    std::shared_ptr<ImageComponent> mScrollDown;
    std::shared_ptr<ScrollIndicatorComponent> mScrollIndicator;
    std::shared_ptr<TextComponent> mSubtitle;
    std::shared_ptr<ComponentGrid> mHeaderGrid;
    std::shared_ptr<ComponentList> mList;
    std::shared_ptr<ComponentGrid> mButtons;

#if !defined(GAMESTICK_OFFLINE)
    ScraperSearchParams mScraperParams;
#endif
    FileData* mGame;
    SystemData* mSystem;

    std::vector<GameControllers> mControllerBadges;
    std::vector<std::shared_ptr<GuiComponent>> mEditors;

    std::vector<MetaDataDecl> mMetaDataDecl;
    MetaDataList* mMetaData;
    std::function<void()> mSavedCallback;
    std::function<void()> mClearGameFunc;
    std::function<void()> mDeleteGameFunc;

    bool mIsCustomCollection;
    bool mMediaFilesUpdated;
    bool mSavedMediaAndAborted;
    bool mInvalidEmulatorEntry;
    bool mInvalidFolderLinkEntry;
};

#endif // ES_APP_GUIS_GUI_META_DATA_ED_H
