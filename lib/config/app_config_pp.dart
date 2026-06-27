class AppConfig {
  // Project Tab Features
  static const bool showNewProjectButton = true;
  static const bool showImportAudioButton = true;
  static const bool showImportVideoButton = true;
  static const bool showSubtitlesButton = false;              //premium
  static const bool showWordsButton = false;                  //premium
  static const bool showPasteButton = true;
  static const bool showVoiceButton = false;                  //premium
  static const bool showJsonButton = false;                   //premium
  static const bool showEditButton = true;
  static const bool showForceAlignButton = false;             //premium
  static const bool showAddMusicButton = true;
  static const bool showAddSFXButton = true;
  static const bool showModelButton = false;                  //premium
  static const bool showAddTextButton = true;
  static const bool showExportButton = true;
  static const bool showExportAssButton = false;              //premium
  static const bool showExportJsonButton = false;             //premium
  static const bool showTimelineColors = false;               //premium
  static const bool showTimelinePanControls = false;            //premium
  static const bool showExportProjectButton = false;            //premium
  static const bool showImportProjectButton = false;            //premium
  static const bool showImportTyposyncButton = false;         //premium
  static const bool showSaveProjectButton = true;
  static const bool showImageTextImportExport = false;           //premium

  // Home Screen Elements
  static const bool showHomeNewProject = true;
  static const bool showHomeAssetsLibrary = true;
  static const bool showHomeTutorials = true;
  static const bool showHomeNativePlayer = false;             //premium
  static const bool showHomeProfile = true;

  // Timeline Tools
  static const bool showTimelineUndo = true;
  static const bool showTimelineRedo = true;
  static const bool showTimelineMarkers = true;
  static const bool showTimelineSplit = true;
  static const bool showTimelineMerge = true;
  static const bool showTimelineDivide = true;
  static const bool showTimelineBurst = true;
  static const bool showTimelineTogether = true;
  static const bool showTimelineDelete = true;
  static const bool showTimelineAddText = true;
  static const bool showTimelineKeyframes = true;
  static const bool showTimelineMultiSelect = true;
  static const bool showTimelineReset = true;
  static const bool showTimelineStack = true;
  static const bool showTimelinePush = true;
  static const bool showTimelineLock = true;
  static const bool showTimelineLoop = true;
  static const bool showTimelineVisibilityToggles = true;
  static const bool showTimelineClipNames = false;
  static const bool showTimelineTrackHeightAdjust = false;    //premium

  // Other global toggles
  static const bool enableAdvancedAnimations = true;
  static const bool showKineticButton = true;             // premium
  static const bool useExperimentalRenderer = true;
  static const bool showSplashScreen = true;
  static const bool showSettingsScreen = true;
  static const bool showExportScreen = true;

  // Local developer master asset import toggle (only used in debug builds or when manually enabled)
  static const bool showImportMasterFolderButton = false;
}
