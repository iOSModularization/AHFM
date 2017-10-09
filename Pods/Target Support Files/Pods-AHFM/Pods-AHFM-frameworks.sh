#!/bin/sh
set -e

echo "mkdir -p ${CONFIGURATION_BUILD_DIR}/${FRAMEWORKS_FOLDER_PATH}"
mkdir -p "${CONFIGURATION_BUILD_DIR}/${FRAMEWORKS_FOLDER_PATH}"

SWIFT_STDLIB_PATH="${DT_TOOLCHAIN_DIR}/usr/lib/swift/${PLATFORM_NAME}"

install_framework()
{
  if [ -r "${BUILT_PRODUCTS_DIR}/$1" ]; then
    local source="${BUILT_PRODUCTS_DIR}/$1"
  elif [ -r "${BUILT_PRODUCTS_DIR}/$(basename "$1")" ]; then
    local source="${BUILT_PRODUCTS_DIR}/$(basename "$1")"
  elif [ -r "$1" ]; then
    local source="$1"
  fi

  local destination="${TARGET_BUILD_DIR}/${FRAMEWORKS_FOLDER_PATH}"

  if [ -L "${source}" ]; then
      echo "Symlinked..."
      source="$(readlink "${source}")"
  fi

  # use filter instead of exclude so missing patterns dont' throw errors
  echo "rsync --delete -av --filter \"- CVS/\" --filter \"- .svn/\" --filter \"- .git/\" --filter \"- .hg/\" --filter \"- Headers\" --filter \"- PrivateHeaders\" --filter \"- Modules\" \"${source}\" \"${destination}\""
  rsync --delete -av --filter "- CVS/" --filter "- .svn/" --filter "- .git/" --filter "- .hg/" --filter "- Headers" --filter "- PrivateHeaders" --filter "- Modules" "${source}" "${destination}"

  local basename
  basename="$(basename -s .framework "$1")"
  binary="${destination}/${basename}.framework/${basename}"
  if ! [ -r "$binary" ]; then
    binary="${destination}/${basename}"
  fi

  # Strip invalid architectures so "fat" simulator / device frameworks work on device
  if [[ "$(file "$binary")" == *"dynamically linked shared library"* ]]; then
    strip_invalid_archs "$binary"
  fi

  # Resign the code if required by the build settings to avoid unstable apps
  code_sign_if_enabled "${destination}/$(basename "$1")"

  # Embed linked Swift runtime libraries. No longer necessary as of Xcode 7.
  if [ "${XCODE_VERSION_MAJOR}" -lt 7 ]; then
    local swift_runtime_libs
    swift_runtime_libs=$(xcrun otool -LX "$binary" | grep --color=never @rpath/libswift | sed -E s/@rpath\\/\(.+dylib\).*/\\1/g | uniq -u  && exit ${PIPESTATUS[0]})
    for lib in $swift_runtime_libs; do
      echo "rsync -auv \"${SWIFT_STDLIB_PATH}/${lib}\" \"${destination}\""
      rsync -auv "${SWIFT_STDLIB_PATH}/${lib}" "${destination}"
      code_sign_if_enabled "${destination}/${lib}"
    done
  fi
}

# Copies the dSYM of a vendored framework
install_dsym() {
  local source="$1"
  if [ -r "$source" ]; then
    echo "rsync --delete -av --filter \"- CVS/\" --filter \"- .svn/\" --filter \"- .git/\" --filter \"- .hg/\" --filter \"- Headers\" --filter \"- PrivateHeaders\" --filter \"- Modules\" \"${source}\" \"${DWARF_DSYM_FOLDER_PATH}\""
    rsync --delete -av --filter "- CVS/" --filter "- .svn/" --filter "- .git/" --filter "- .hg/" --filter "- Headers" --filter "- PrivateHeaders" --filter "- Modules" "${source}" "${DWARF_DSYM_FOLDER_PATH}"
  fi
}

# Signs a framework with the provided identity
code_sign_if_enabled() {
  if [ -n "${EXPANDED_CODE_SIGN_IDENTITY}" -a "${CODE_SIGNING_REQUIRED}" != "NO" -a "${CODE_SIGNING_ALLOWED}" != "NO" ]; then
    # Use the current code_sign_identitiy
    echo "Code Signing $1 with Identity ${EXPANDED_CODE_SIGN_IDENTITY_NAME}"
    local code_sign_cmd="/usr/bin/codesign --force --sign ${EXPANDED_CODE_SIGN_IDENTITY} ${OTHER_CODE_SIGN_FLAGS} --preserve-metadata=identifier,entitlements '$1'"

    if [ "${COCOAPODS_PARALLEL_CODE_SIGN}" == "true" ]; then
      code_sign_cmd="$code_sign_cmd &"
    fi
    echo "$code_sign_cmd"
    eval "$code_sign_cmd"
  fi
}

# Strip invalid architectures
strip_invalid_archs() {
  binary="$1"
  # Get architectures for current file
  archs="$(lipo -info "$binary" | rev | cut -d ':' -f1 | rev)"
  stripped=""
  for arch in $archs; do
    if ! [[ "${ARCHS}" == *"$arch"* ]]; then
      # Strip non-valid architectures in-place
      lipo -remove "$arch" -output "$binary" "$binary" || exit 1
      stripped="$stripped $arch"
    fi
  done
  if [[ "$stripped" ]]; then
    echo "Stripped $binary of architectures:$stripped"
  fi
}


if [[ "$CONFIGURATION" == "Debug" ]]; then
  install_framework "${BUILT_PRODUCTS_DIR}/AHAudioPlayer/AHAudioPlayer.framework"
  install_framework "${BUILT_PRODUCTS_DIR}/AHBannerView/AHBannerView.framework"
  install_framework "${BUILT_PRODUCTS_DIR}/AHCategoryView/AHCategoryView.framework"
  install_framework "${BUILT_PRODUCTS_DIR}/AHDataModel/AHDataModel.framework"
  install_framework "${BUILT_PRODUCTS_DIR}/AHDownloadTool/AHDownloadTool.framework"
  install_framework "${BUILT_PRODUCTS_DIR}/AHDownloader/AHDownloader.framework"
  install_framework "${BUILT_PRODUCTS_DIR}/AHDraggableLayout/AHDraggableLayout.framework"
  install_framework "${BUILT_PRODUCTS_DIR}/AHFMAudioPlayerManager/AHFMAudioPlayerManager.framework"
  install_framework "${BUILT_PRODUCTS_DIR}/AHFMAudioPlayerVC/AHFMAudioPlayerVC.framework"
  install_framework "${BUILT_PRODUCTS_DIR}/AHFMAudioPlayerVCManager/AHFMAudioPlayerVCManager.framework"
  install_framework "${BUILT_PRODUCTS_DIR}/AHFMAudioPlayerVCServices/AHFMAudioPlayerVCServices.framework"
  install_framework "${BUILT_PRODUCTS_DIR}/AHFMBottomPlayer/AHFMBottomPlayer.framework"
  install_framework "${BUILT_PRODUCTS_DIR}/AHFMBottomPlayerManager/AHFMBottomPlayerManager.framework"
  install_framework "${BUILT_PRODUCTS_DIR}/AHFMBottomPlayerServices/AHFMBottomPlayerServices.framework"
  install_framework "${BUILT_PRODUCTS_DIR}/AHFMCategoryVC/AHFMCategoryVC.framework"
  install_framework "${BUILT_PRODUCTS_DIR}/AHFMCategoryVCManager/AHFMCategoryVCManager.framework"
  install_framework "${BUILT_PRODUCTS_DIR}/AHFMCategoryVCServices/AHFMCategoryVCServices.framework"
  install_framework "${BUILT_PRODUCTS_DIR}/AHFMDataCenter/AHFMDataCenter.framework"
  install_framework "${BUILT_PRODUCTS_DIR}/AHFMDataTransformers/AHFMDataTransformers.framework"
  install_framework "${BUILT_PRODUCTS_DIR}/AHFMDownloadCenter/AHFMDownloadCenter.framework"
  install_framework "${BUILT_PRODUCTS_DIR}/AHFMDownloadCenterManager/AHFMDownloadCenterManager.framework"
  install_framework "${BUILT_PRODUCTS_DIR}/AHFMDownloadCenterServices/AHFMDownloadCenterServices.framework"
  install_framework "${BUILT_PRODUCTS_DIR}/AHFMDownloadList/AHFMDownloadList.framework"
  install_framework "${BUILT_PRODUCTS_DIR}/AHFMDownloadListManager/AHFMDownloadListManager.framework"
  install_framework "${BUILT_PRODUCTS_DIR}/AHFMDownloadListServices/AHFMDownloadListServices.framework"
  install_framework "${BUILT_PRODUCTS_DIR}/AHFMDownloaderManager/AHFMDownloaderManager.framework"
  install_framework "${BUILT_PRODUCTS_DIR}/AHFMEpisodeListVC/AHFMEpisodeListVC.framework"
  install_framework "${BUILT_PRODUCTS_DIR}/AHFMEpisodeListVCManager/AHFMEpisodeListVCManager.framework"
  install_framework "${BUILT_PRODUCTS_DIR}/AHFMEpisodeListVCServices/AHFMEpisodeListVCServices.framework"
  install_framework "${BUILT_PRODUCTS_DIR}/AHFMFeature/AHFMFeature.framework"
  install_framework "${BUILT_PRODUCTS_DIR}/AHFMFeatureManager/AHFMFeatureManager.framework"
  install_framework "${BUILT_PRODUCTS_DIR}/AHFMFeatureServices/AHFMFeatureServices.framework"
  install_framework "${BUILT_PRODUCTS_DIR}/AHFMHistoryVC/AHFMHistoryVC.framework"
  install_framework "${BUILT_PRODUCTS_DIR}/AHFMHistoryVCManager/AHFMHistoryVCManager.framework"
  install_framework "${BUILT_PRODUCTS_DIR}/AHFMHistoryVCServices/AHFMHistoryVCServices.framework"
  install_framework "${BUILT_PRODUCTS_DIR}/AHFMKeywordVC/AHFMKeywordVC.framework"
  install_framework "${BUILT_PRODUCTS_DIR}/AHFMKeywordVCManager/AHFMKeywordVCManager.framework"
  install_framework "${BUILT_PRODUCTS_DIR}/AHFMKeywordVCServices/AHFMKeywordVCServices.framework"
  install_framework "${BUILT_PRODUCTS_DIR}/AHFMMain/AHFMMain.framework"
  install_framework "${BUILT_PRODUCTS_DIR}/AHFMMainManager/AHFMMainManager.framework"
  install_framework "${BUILT_PRODUCTS_DIR}/AHFMMainServices/AHFMMainServices.framework"
  install_framework "${BUILT_PRODUCTS_DIR}/AHFMModuleManager/AHFMModuleManager.framework"
  install_framework "${BUILT_PRODUCTS_DIR}/AHFMNetworking/AHFMNetworking.framework"
  install_framework "${BUILT_PRODUCTS_DIR}/AHFMSearchVC/AHFMSearchVC.framework"
  install_framework "${BUILT_PRODUCTS_DIR}/AHFMSearchVCManager/AHFMSearchVCManager.framework"
  install_framework "${BUILT_PRODUCTS_DIR}/AHFMSearchVCService/AHFMSearchVCService.framework"
  install_framework "${BUILT_PRODUCTS_DIR}/AHFMSearchVCServices/AHFMSearchVCServices.framework"
  install_framework "${BUILT_PRODUCTS_DIR}/AHFMServices/AHFMServices.framework"
  install_framework "${BUILT_PRODUCTS_DIR}/AHFMShowPage/AHFMShowPage.framework"
  install_framework "${BUILT_PRODUCTS_DIR}/AHFMShowPageManger/AHFMShowPageManger.framework"
  install_framework "${BUILT_PRODUCTS_DIR}/AHFMShowPageServices/AHFMShowPageServices.framework"
  install_framework "${BUILT_PRODUCTS_DIR}/AHFMUserCenter/AHFMUserCenter.framework"
  install_framework "${BUILT_PRODUCTS_DIR}/AHFMUserCenterManager/AHFMUserCenterManager.framework"
  install_framework "${BUILT_PRODUCTS_DIR}/AHFMUserCenterServices/AHFMUserCenterServices.framework"
  install_framework "${BUILT_PRODUCTS_DIR}/AHFloatingTextView/AHFloatingTextView.framework"
  install_framework "${BUILT_PRODUCTS_DIR}/AHNibLoadable/AHNibLoadable.framework"
  install_framework "${BUILT_PRODUCTS_DIR}/AHProgressSlider/AHProgressSlider.framework"
  install_framework "${BUILT_PRODUCTS_DIR}/AHServiceRouter/AHServiceRouter.framework"
  install_framework "${BUILT_PRODUCTS_DIR}/AHStackButton/AHStackButton.framework"
  install_framework "${BUILT_PRODUCTS_DIR}/Alamofire/Alamofire.framework"
  install_framework "${BUILT_PRODUCTS_DIR}/BundleExtension/BundleExtension.framework"
  install_framework "${BUILT_PRODUCTS_DIR}/KeychainAccess/KeychainAccess.framework"
  install_framework "${BUILT_PRODUCTS_DIR}/SDWebImage/SDWebImage.framework"
  install_framework "${BUILT_PRODUCTS_DIR}/SVProgressHUD/SVProgressHUD.framework"
  install_framework "${BUILT_PRODUCTS_DIR}/StringExtension/StringExtension.framework"
  install_framework "${BUILT_PRODUCTS_DIR}/SwiftyJSON/SwiftyJSON.framework"
  install_framework "${BUILT_PRODUCTS_DIR}/UIDeviceExtension/UIDeviceExtension.framework"
  install_framework "${BUILT_PRODUCTS_DIR}/UIImageExtension/UIImageExtension.framework"
fi
if [[ "$CONFIGURATION" == "Release" ]]; then
  install_framework "${BUILT_PRODUCTS_DIR}/AHAudioPlayer/AHAudioPlayer.framework"
  install_framework "${BUILT_PRODUCTS_DIR}/AHBannerView/AHBannerView.framework"
  install_framework "${BUILT_PRODUCTS_DIR}/AHCategoryView/AHCategoryView.framework"
  install_framework "${BUILT_PRODUCTS_DIR}/AHDataModel/AHDataModel.framework"
  install_framework "${BUILT_PRODUCTS_DIR}/AHDownloadTool/AHDownloadTool.framework"
  install_framework "${BUILT_PRODUCTS_DIR}/AHDownloader/AHDownloader.framework"
  install_framework "${BUILT_PRODUCTS_DIR}/AHDraggableLayout/AHDraggableLayout.framework"
  install_framework "${BUILT_PRODUCTS_DIR}/AHFMAudioPlayerManager/AHFMAudioPlayerManager.framework"
  install_framework "${BUILT_PRODUCTS_DIR}/AHFMAudioPlayerVC/AHFMAudioPlayerVC.framework"
  install_framework "${BUILT_PRODUCTS_DIR}/AHFMAudioPlayerVCManager/AHFMAudioPlayerVCManager.framework"
  install_framework "${BUILT_PRODUCTS_DIR}/AHFMAudioPlayerVCServices/AHFMAudioPlayerVCServices.framework"
  install_framework "${BUILT_PRODUCTS_DIR}/AHFMBottomPlayer/AHFMBottomPlayer.framework"
  install_framework "${BUILT_PRODUCTS_DIR}/AHFMBottomPlayerManager/AHFMBottomPlayerManager.framework"
  install_framework "${BUILT_PRODUCTS_DIR}/AHFMBottomPlayerServices/AHFMBottomPlayerServices.framework"
  install_framework "${BUILT_PRODUCTS_DIR}/AHFMCategoryVC/AHFMCategoryVC.framework"
  install_framework "${BUILT_PRODUCTS_DIR}/AHFMCategoryVCManager/AHFMCategoryVCManager.framework"
  install_framework "${BUILT_PRODUCTS_DIR}/AHFMCategoryVCServices/AHFMCategoryVCServices.framework"
  install_framework "${BUILT_PRODUCTS_DIR}/AHFMDataCenter/AHFMDataCenter.framework"
  install_framework "${BUILT_PRODUCTS_DIR}/AHFMDataTransformers/AHFMDataTransformers.framework"
  install_framework "${BUILT_PRODUCTS_DIR}/AHFMDownloadCenter/AHFMDownloadCenter.framework"
  install_framework "${BUILT_PRODUCTS_DIR}/AHFMDownloadCenterManager/AHFMDownloadCenterManager.framework"
  install_framework "${BUILT_PRODUCTS_DIR}/AHFMDownloadCenterServices/AHFMDownloadCenterServices.framework"
  install_framework "${BUILT_PRODUCTS_DIR}/AHFMDownloadList/AHFMDownloadList.framework"
  install_framework "${BUILT_PRODUCTS_DIR}/AHFMDownloadListManager/AHFMDownloadListManager.framework"
  install_framework "${BUILT_PRODUCTS_DIR}/AHFMDownloadListServices/AHFMDownloadListServices.framework"
  install_framework "${BUILT_PRODUCTS_DIR}/AHFMDownloaderManager/AHFMDownloaderManager.framework"
  install_framework "${BUILT_PRODUCTS_DIR}/AHFMEpisodeListVC/AHFMEpisodeListVC.framework"
  install_framework "${BUILT_PRODUCTS_DIR}/AHFMEpisodeListVCManager/AHFMEpisodeListVCManager.framework"
  install_framework "${BUILT_PRODUCTS_DIR}/AHFMEpisodeListVCServices/AHFMEpisodeListVCServices.framework"
  install_framework "${BUILT_PRODUCTS_DIR}/AHFMFeature/AHFMFeature.framework"
  install_framework "${BUILT_PRODUCTS_DIR}/AHFMFeatureManager/AHFMFeatureManager.framework"
  install_framework "${BUILT_PRODUCTS_DIR}/AHFMFeatureServices/AHFMFeatureServices.framework"
  install_framework "${BUILT_PRODUCTS_DIR}/AHFMHistoryVC/AHFMHistoryVC.framework"
  install_framework "${BUILT_PRODUCTS_DIR}/AHFMHistoryVCManager/AHFMHistoryVCManager.framework"
  install_framework "${BUILT_PRODUCTS_DIR}/AHFMHistoryVCServices/AHFMHistoryVCServices.framework"
  install_framework "${BUILT_PRODUCTS_DIR}/AHFMKeywordVC/AHFMKeywordVC.framework"
  install_framework "${BUILT_PRODUCTS_DIR}/AHFMKeywordVCManager/AHFMKeywordVCManager.framework"
  install_framework "${BUILT_PRODUCTS_DIR}/AHFMKeywordVCServices/AHFMKeywordVCServices.framework"
  install_framework "${BUILT_PRODUCTS_DIR}/AHFMMain/AHFMMain.framework"
  install_framework "${BUILT_PRODUCTS_DIR}/AHFMMainManager/AHFMMainManager.framework"
  install_framework "${BUILT_PRODUCTS_DIR}/AHFMMainServices/AHFMMainServices.framework"
  install_framework "${BUILT_PRODUCTS_DIR}/AHFMModuleManager/AHFMModuleManager.framework"
  install_framework "${BUILT_PRODUCTS_DIR}/AHFMNetworking/AHFMNetworking.framework"
  install_framework "${BUILT_PRODUCTS_DIR}/AHFMSearchVC/AHFMSearchVC.framework"
  install_framework "${BUILT_PRODUCTS_DIR}/AHFMSearchVCManager/AHFMSearchVCManager.framework"
  install_framework "${BUILT_PRODUCTS_DIR}/AHFMSearchVCService/AHFMSearchVCService.framework"
  install_framework "${BUILT_PRODUCTS_DIR}/AHFMSearchVCServices/AHFMSearchVCServices.framework"
  install_framework "${BUILT_PRODUCTS_DIR}/AHFMServices/AHFMServices.framework"
  install_framework "${BUILT_PRODUCTS_DIR}/AHFMShowPage/AHFMShowPage.framework"
  install_framework "${BUILT_PRODUCTS_DIR}/AHFMShowPageManger/AHFMShowPageManger.framework"
  install_framework "${BUILT_PRODUCTS_DIR}/AHFMShowPageServices/AHFMShowPageServices.framework"
  install_framework "${BUILT_PRODUCTS_DIR}/AHFMUserCenter/AHFMUserCenter.framework"
  install_framework "${BUILT_PRODUCTS_DIR}/AHFMUserCenterManager/AHFMUserCenterManager.framework"
  install_framework "${BUILT_PRODUCTS_DIR}/AHFMUserCenterServices/AHFMUserCenterServices.framework"
  install_framework "${BUILT_PRODUCTS_DIR}/AHFloatingTextView/AHFloatingTextView.framework"
  install_framework "${BUILT_PRODUCTS_DIR}/AHNibLoadable/AHNibLoadable.framework"
  install_framework "${BUILT_PRODUCTS_DIR}/AHProgressSlider/AHProgressSlider.framework"
  install_framework "${BUILT_PRODUCTS_DIR}/AHServiceRouter/AHServiceRouter.framework"
  install_framework "${BUILT_PRODUCTS_DIR}/AHStackButton/AHStackButton.framework"
  install_framework "${BUILT_PRODUCTS_DIR}/Alamofire/Alamofire.framework"
  install_framework "${BUILT_PRODUCTS_DIR}/BundleExtension/BundleExtension.framework"
  install_framework "${BUILT_PRODUCTS_DIR}/KeychainAccess/KeychainAccess.framework"
  install_framework "${BUILT_PRODUCTS_DIR}/SDWebImage/SDWebImage.framework"
  install_framework "${BUILT_PRODUCTS_DIR}/SVProgressHUD/SVProgressHUD.framework"
  install_framework "${BUILT_PRODUCTS_DIR}/StringExtension/StringExtension.framework"
  install_framework "${BUILT_PRODUCTS_DIR}/SwiftyJSON/SwiftyJSON.framework"
  install_framework "${BUILT_PRODUCTS_DIR}/UIDeviceExtension/UIDeviceExtension.framework"
  install_framework "${BUILT_PRODUCTS_DIR}/UIImageExtension/UIImageExtension.framework"
fi
if [ "${COCOAPODS_PARALLEL_CODE_SIGN}" == "true" ]; then
  wait
fi
