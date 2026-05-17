#!/usr/bin/env python3
"""Generate DockWalk.xcodeproj/project.pbxproj from Swift sources on disk."""

from __future__ import annotations

import os
import uuid
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1] / "apps/ios/dockwalk"
SRC_ROOT = ROOT / "DockWalk"
TEST_ROOT = ROOT / "DockWalkTests"
OUT = ROOT / "DockWalk.xcodeproj" / "project.pbxproj"


def uid() -> str:
    return uuid.uuid4().hex[:24].upper()


def collect_swift(root: Path) -> list[str]:
    files: list[str] = []
    for path in sorted(root.rglob("*.swift")):
        files.append(path.relative_to(root).as_posix())
    return files


def main() -> None:
    swift_files = collect_swift(SRC_ROOT)
    test_files = collect_swift(TEST_ROOT)

    # Stable-ish IDs for key objects
    PROJ = uid()
    MAIN_GROUP = uid()
    PRODUCTS_GROUP = uid()
    DOCKWALK_GROUP = uid()
    TESTS_GROUP = uid()
    RESOURCES_GROUP = uid()
    PRODUCT_APP = uid()
    PRODUCT_TEST = uid()
    TARGET_APP = uid()
    TARGET_TEST = uid()
    SOURCES_APP = uid()
    SOURCES_TEST = uid()
    FRAMEWORKS_APP = uid()
    FRAMEWORKS_TEST = uid()
    RESOURCES_PHASE = uid()
    CONFIG_LIST_PROJ = uid()
    CONFIG_LIST_APP = uid()
    CONFIG_LIST_TEST = uid()
    DEBUG_PROJ = uid()
    RELEASE_PROJ = uid()
    DEBUG_APP = uid()
    RELEASE_APP = uid()
    DEBUG_TEST = uid()
    RELEASE_TEST = uid()
    TARGET_DEP = uid()
    CONTAINER_PROXY = uid()

    file_ref: dict[str, str] = {}
    build_app: dict[str, str] = {}
    build_test: dict[str, str] = {}
    groups: dict[str, str] = {}

    def ref(path: str) -> str:
        if path not in file_ref:
            file_ref[path] = uid()
        return file_ref[path]

    for sf in swift_files:
        ref(sf)
        build_app[sf] = uid()

    for tf in test_files:
        key = f"tests/{tf}"
        ref(key)
        build_test[tf] = uid()

    ASSETS = "Resources/Assets.xcassets"
    INFO = "Resources/Info.plist"
    ref(ASSETS)
    ref(INFO)
    build_assets = uid()

    # Directory groups under DockWalk
    dirs: set[str] = set()
    for sf in swift_files:
        parts = sf.split("/")
        for i in range(1, len(parts)):
            dirs.add("/".join(parts[:i]))
    for d in sorted(dirs, key=lambda x: (x.count("/"), x)):
        groups[d] = uid()
    groups["Resources"] = RESOURCES_GROUP

    lines: list[str] = []

    def w(s: str = "") -> None:
        lines.append(s)

    w("// !$*UTF8*$!")
    w("{")
    w("\tarchiveVersion = 1;")
    w("\tclasses = {};")
    w("\tobjectVersion = 56;")
    w("\tobjects = {")

    w("\n/* Begin PBXBuildFile section */")
    for sf, bid in build_app.items():
        base = os.path.basename(sf)
        w(f"\t\t{bid} /* {base} in Sources */ = {{isa = PBXBuildFile; fileRef = {ref(sf)} /* {base} */; }};")
    w(
        f"\t\t{build_assets} /* Assets.xcassets in Resources */ = {{isa = PBXBuildFile; fileRef = {ref(ASSETS)} /* Assets.xcassets */; }};"
    )
    for tf, bid in build_test.items():
        w(f"\t\t{bid} /* {tf} in Sources */ = {{isa = PBXBuildFile; fileRef = {ref(f'tests/{tf}')} /* {tf} */; }};")
    w("/* End PBXBuildFile section */")

    w("\n/* Begin PBXFileReference section */")
    w(
        f"\t\t{PRODUCT_APP} /* DockWalk.app */ = {{isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = DockWalk.app; sourceTree = BUILT_PRODUCTS_DIR; }};"
    )
    w(
        f"\t\t{PRODUCT_TEST} /* DockWalkTests.xctest */ = {{isa = PBXFileReference; explicitFileType = wrapper.cfbundle; includeInIndex = 0; path = DockWalkTests.xctest; sourceTree = BUILT_PRODUCTS_DIR; }};"
    )
    for path, rid in file_ref.items():
        name = os.path.basename(path)
        if path.endswith(".xcassets"):
            w(
                f"\t\t{rid} /* {name} */ = {{isa = PBXFileReference; lastKnownFileType = folder.assetcatalog; name = {name}; path = {path}; sourceTree = \"<group>\"; }};"
            )
        elif path.endswith(".plist"):
            w(
                f"\t\t{rid} /* {name} */ = {{isa = PBXFileReference; lastKnownFileType = text.plist.xml; name = {name}; path = {path}; sourceTree = \"<group>\"; }};"
            )
        elif path.startswith("tests/"):
            w(
                f"\t\t{rid} /* {name} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {name}; sourceTree = \"<group>\"; }};"
            )
        else:
            w(
                f"\t\t{rid} /* {name} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; name = {name}; path = {path}; sourceTree = \"<group>\"; }};"
            )
    w("/* End PBXFileReference section */")

    w("\n/* Begin PBXFrameworksBuildPhase section */")
    for phase_id, name in [(FRAMEWORKS_APP, "App"), (FRAMEWORKS_TEST, "Tests")]:
        w(f"\t\t{phase_id} /* Frameworks */ = {{")
        w("\t\t\tisa = PBXFrameworksBuildPhase;")
        w("\t\t\tbuildActionMask = 2147483647;")
        w("\t\t\tfiles = ();")
        w("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
        w("\t\t};")
    w("/* End PBXFrameworksBuildPhase section */")

    w("\n/* Begin PBXGroup section */")
    w(f"\t\t{MAIN_GROUP} = {{")
    w("\t\t\tisa = PBXGroup;")
    w("\t\t\tchildren = (")
    w(f"\t\t\t\t{DOCKWALK_GROUP} /* DockWalk */,")
    w(f"\t\t\t\t{TESTS_GROUP} /* DockWalkTests */,")
    w(f"\t\t\t\t{PRODUCTS_GROUP} /* Products */,")
    w("\t\t\t);")
    w("\t\t\tsourceTree = \"<group>\";")
    w("\t\t};")

    w(f"\t\t{PRODUCTS_GROUP} /* Products */ = {{")
    w("\t\t\tisa = PBXGroup;")
    w("\t\t\tchildren = (")
    w(f"\t\t\t\t{PRODUCT_APP} /* DockWalk.app */,")
    w(f"\t\t\t\t{PRODUCT_TEST} /* DockWalkTests.xctest */,")
    w("\t\t\t);")
    w("\t\t\tname = Products;")
    w("\t\t\tsourceTree = \"<group>\";")
    w("\t\t};")

    top_level = sorted({sf.split("/")[0] for sf in swift_files} | {"Resources"})
    w(f"\t\t{DOCKWALK_GROUP} /* DockWalk */ = {{")
    w("\t\t\tisa = PBXGroup;")
    w("\t\t\tchildren = (")
    for name in top_level:
        if name == "Resources":
            w(f"\t\t\t\t{RESOURCES_GROUP} /* Resources */,")
        else:
            w(f"\t\t\t\t{groups[name]} /* {name} */,")
    w("\t\t\t);")
    w("\t\t\tpath = DockWalk;")
    w("\t\t\tsourceTree = \"<group>\";")
    w("\t\t};")

    for d in sorted(dirs, key=lambda x: (x.count("/"), x)):
        gid = groups[d]
        w(f"\t\t{gid} /* {os.path.basename(d)} */ = {{")
        w("\t\t\tisa = PBXGroup;")
        w("\t\t\tchildren = (")
        subdirs = sorted(
            {
                sf.split("/")[len(d.split("/"))]
                for sf in swift_files
                if sf.startswith(d + "/") and "/" in sf[len(d) + 1 :]
            }
        )
        for sf in swift_files:
            if sf.count("/") == d.count("/") and sf.startswith(d + "/"):
                w(f"\t\t\t\t{ref(sf)} /* {os.path.basename(sf)} */,")
        for sub in subdirs:
            sub_path = f"{d}/{sub}"
            if sub_path in groups:
                w(f"\t\t\t\t{groups[sub_path]} /* {sub} */,")
        w("\t\t\t);")
        w(f"\t\t\tpath = {os.path.basename(d)};")
        w("\t\t\tsourceTree = \"<group>\";")
        w("\t\t};")

    w(f"\t\t{RESOURCES_GROUP} /* Resources */ = {{")
    w("\t\t\tisa = PBXGroup;")
    w("\t\t\tchildren = (")
    w(f"\t\t\t\t{ref(ASSETS)} /* Assets.xcassets */,")
    w(f"\t\t\t\t{ref(INFO)} /* Info.plist */,")
    w("\t\t\t);")
    w("\t\t\tpath = Resources;")
    w("\t\t\tsourceTree = \"<group>\";")
    w("\t\t};")

    w(f"\t\t{TESTS_GROUP} /* DockWalkTests */ = {{")
    w("\t\t\tisa = PBXGroup;")
    w("\t\t\tchildren = (")
    for tf in test_files:
        w(f"\t\t\t\t{ref(f'tests/{tf}')} /* {tf} */,")
    w("\t\t\t);")
    w("\t\t\tpath = DockWalkTests;")
    w("\t\t\tsourceTree = \"<group>\";")
    w("\t\t};")
    w("/* End PBXGroup section */")

    w("\n/* Begin PBXNativeTarget section */")
    w(f"\t\t{TARGET_APP} /* DockWalk */ = {{")
    w("\t\t\tisa = PBXNativeTarget;")
    w(f"\t\t\tbuildConfigurationList = {CONFIG_LIST_APP} /* Build configuration list for PBXNativeTarget \"DockWalk\" */;")
    w("\t\t\tbuildPhases = (")
    w(f"\t\t\t\t{SOURCES_APP} /* Sources */,")
    w(f"\t\t\t\t{FRAMEWORKS_APP} /* Frameworks */,")
    w(f"\t\t\t\t{RESOURCES_PHASE} /* Resources */,")
    w("\t\t\t);")
    w("\t\t\tbuildRules = ();")
    w("\t\t\tdependencies = ();")
    w("\t\t\tname = DockWalk;")
    w("\t\t\tproductName = DockWalk;")
    w(f"\t\t\tproductReference = {PRODUCT_APP} /* DockWalk.app */;")
    w('\t\t\tproductType = "com.apple.product-type.application";')
    w("\t\t};")

    w(f"\t\t{TARGET_TEST} /* DockWalkTests */ = {{")
    w("\t\t\tisa = PBXNativeTarget;")
    w(f"\t\t\tbuildConfigurationList = {CONFIG_LIST_TEST} /* Build configuration list for PBXNativeTarget \"DockWalkTests\" */;")
    w("\t\t\tbuildPhases = (")
    w(f"\t\t\t\t{SOURCES_TEST} /* Sources */,")
    w(f"\t\t\t\t{FRAMEWORKS_TEST} /* Frameworks */,")
    w("\t\t\t);")
    w("\t\t\tbuildRules = ();")
    w("\t\t\tdependencies = (")
    w(f"\t\t\t\t{TARGET_DEP} /* PBXTargetDependency */,")
    w("\t\t\t);")
    w("\t\t\tname = DockWalkTests;")
    w("\t\t\tproductName = DockWalkTests;")
    w(f"\t\t\tproductReference = {PRODUCT_TEST} /* DockWalkTests.xctest */;")
    w('\t\t\tproductType = "com.apple.product-type.bundle.unit-test";')
    w("\t\t};")
    w("/* End PBXNativeTarget section */")

    w("\n/* Begin PBXProject section */")
    w(f"\t\t{PROJ} /* Project object */ = {{")
    w("\t\t\tisa = PBXProject;")
    w("\t\t\tattributes = {")
    w("\t\t\t\tBuildIndependentTargetsInParallel = 1;")
    w("\t\t\t\tLastSwiftUpdateCheck = 1600;")
    w("\t\t\t\tLastUpgradeCheck = 1600;")
    w("\t\t\t\tTargetAttributes = {")
    w(f"\t\t\t\t\t{TARGET_APP} = {{ CreatedOnToolsVersion = 16.0; }};")
    w(f"\t\t\t\t\t{TARGET_TEST} = {{ CreatedOnToolsVersion = 16.0; TestTargetID = {TARGET_APP}; }};")
    w("\t\t\t\t};")
    w("\t\t\t};")
    w(f"\t\t\tbuildConfigurationList = {CONFIG_LIST_PROJ} /* Build configuration list for PBXProject \"DockWalk\" */;")
    w("\t\t\tcompatibilityVersion = \"Xcode 14.0\";")
    w("\t\t\tdevelopmentRegion = en;")
    w("\t\t\thasScannedForEncodings = 0;")
    w("\t\t\tknownRegions = (en, Base);")
    w(f"\t\t\tmainGroup = {MAIN_GROUP};")
    w(f"\t\t\tproductRefGroup = {PRODUCTS_GROUP} /* Products */;")
    w("\t\t\tprojectDirPath = \"\";")
    w("\t\t\tprojectRoot = \"\";")
    w("\t\t\ttargets = (")
    w(f"\t\t\t\t{TARGET_APP} /* DockWalk */,")
    w(f"\t\t\t\t{TARGET_TEST} /* DockWalkTests */,")
    w("\t\t\t);")
    w("\t\t};")
    w("/* End PBXProject section */")

    w("\n/* Begin PBXResourcesBuildPhase section */")
    w(f"\t\t{RESOURCES_PHASE} /* Resources */ = {{")
    w("\t\t\tisa = PBXResourcesBuildPhase;")
    w("\t\t\tbuildActionMask = 2147483647;")
    w("\t\t\tfiles = (")
    w(f"\t\t\t\t{build_assets} /* Assets.xcassets in Resources */,")
    w("\t\t\t);")
    w("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
    w("\t\t};")
    w("/* End PBXResourcesBuildPhase section */")

    w("\n/* Begin PBXSourcesBuildPhase section */")
    w(f"\t\t{SOURCES_APP} /* Sources */ = {{")
    w("\t\t\tisa = PBXSourcesBuildPhase;")
    w("\t\t\tbuildActionMask = 2147483647;")
    w("\t\t\tfiles = (")
    for bid in build_app.values():
        w(f"\t\t\t\t{bid} /* in Sources */,")
    w("\t\t\t);")
    w("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
    w("\t\t};")

    w(f"\t\t{SOURCES_TEST} /* Sources */ = {{")
    w("\t\t\tisa = PBXSourcesBuildPhase;")
    w("\t\t\tbuildActionMask = 2147483647;")
    w("\t\t\tfiles = (")
    for bid in build_test.values():
        w(f"\t\t\t\t{bid} /* in Sources */,")
    w("\t\t\t);")
    w("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
    w("\t\t};")
    w("/* End PBXSourcesBuildPhase section */")

    w("\n/* Begin PBXContainerItemProxy section */")
    w(f"\t\t{CONTAINER_PROXY} /* PBXContainerItemProxy */ = {{")
    w("\t\t\tisa = PBXContainerItemProxy;")
    w("\t\t\tcontainerPortal = {PROJ} /* Project object */;")
    w("\t\t\tproxyType = 1;")
    w(f"\t\t\tremoteGlobalIDString = {TARGET_APP};")
    w("\t\t\tremoteInfo = DockWalk;")
    w("\t\t};")
    w("/* End PBXContainerItemProxy section */")

    w("\n/* Begin PBXTargetDependency section */")
    w(f"\t\t{TARGET_DEP} /* PBXTargetDependency */ = {{")
    w("\t\t\tisa = PBXTargetDependency;")
    w(f"\t\t\ttarget = {TARGET_APP} /* DockWalk */;")
    w(f"\t\t\ttargetProxy = {CONTAINER_PROXY} /* PBXContainerItemProxy */;")
    w("\t\t};")
    w("/* End PBXTargetDependency section */")

    def xcconfig_list(list_id: str, name: str, debug_id: str, release_id: str) -> None:
        w(f"\t\t{list_id} /* Build configuration list for {name} */ = {{")
        w("\t\t\tisa = XCConfigurationList;")
        w("\t\t\tbuildConfigurations = (")
        w(f"\t\t\t\t{debug_id} /* Debug */,")
        w(f"\t\t\t\t{release_id} /* Release */,")
        w("\t\t\t);")
        w("\t\t\tdefaultConfigurationIsVisible = 0;")
        w("\t\t\tdefaultConfigurationName = Release;")
        w("\t\t};")

    w("\n/* Begin XCBuildConfiguration section */")
    for cfg_id, name, settings in [
        (
            DEBUG_PROJ,
            "Debug",
            {
                "ALWAYS_SEARCH_USER_PATHS": "NO",
                "CLANG_ENABLE_MODULES": "YES",
                "CLANG_ENABLE_OBJC_ARC": "YES",
                "COPY_PHASE_STRIP": "NO",
                "DEBUG_INFORMATION_FORMAT": "dwarf",
                "ENABLE_TESTABILITY": "YES",
                "GCC_DYNAMIC_NO_PIC": "NO",
                "GCC_OPTIMIZATION_LEVEL": "0",
                "IPHONEOS_DEPLOYMENT_TARGET": "17.0",
                "MTL_ENABLE_DEBUG_INFO": "INCLUDE_SOURCE",
                "ONLY_ACTIVE_ARCH": "YES",
                "SDKROOT": "iphoneos",
                "SWIFT_ACTIVE_COMPILATION_CONDITIONS": "DEBUG",
                "SWIFT_OPTIMIZATION_LEVEL": "-Onone",
            },
        ),
        (
            RELEASE_PROJ,
            "Release",
            {
                "ALWAYS_SEARCH_USER_PATHS": "NO",
                "CLANG_ENABLE_MODULES": "YES",
                "CLANG_ENABLE_OBJC_ARC": "YES",
                "COPY_PHASE_STRIP": "NO",
                "DEBUG_INFORMATION_FORMAT": "dwarf-with-dsym",
                "IPHONEOS_DEPLOYMENT_TARGET": "17.0",
                "SDKROOT": "iphoneos",
                "SWIFT_COMPILATION_MODE": "wholemodule",
                "VALIDATE_PRODUCT": "YES",
            },
        ),
        (
            DEBUG_APP,
            "Debug",
            {
                "CODE_SIGN_STYLE": "Automatic",
                "CURRENT_PROJECT_VERSION": "1",
                "DEVELOPMENT_TEAM": "",
                "GENERATE_INFOPLIST_FILE": "NO",
                "INFOPLIST_FILE": "DockWalk/Resources/Info.plist",
                "LD_RUNPATH_SEARCH_PATHS": (
                    "$(inherited) @executable_path/Frameworks"
                ),
                "MARKETING_VERSION": "0.1.0",
                "PRODUCT_BUNDLE_IDENTIFIER": "io.skyprairie.dockwalk",
                "PRODUCT_NAME": "$(TARGET_NAME)",
                "SWIFT_EMIT_LOC_STRINGS": "YES",
                "SWIFT_VERSION": "5.0",
                "TARGETED_DEVICE_FAMILY": "1,2",
            },
        ),
        (
            RELEASE_APP,
            "Release",
            {
                "CODE_SIGN_STYLE": "Automatic",
                "CURRENT_PROJECT_VERSION": "1",
                "DEVELOPMENT_TEAM": "",
                "GENERATE_INFOPLIST_FILE": "NO",
                "INFOPLIST_FILE": "DockWalk/Resources/Info.plist",
                "LD_RUNPATH_SEARCH_PATHS": (
                    "$(inherited) @executable_path/Frameworks"
                ),
                "MARKETING_VERSION": "0.1.0",
                "PRODUCT_BUNDLE_IDENTIFIER": "io.skyprairie.dockwalk",
                "PRODUCT_NAME": "$(TARGET_NAME)",
                "SWIFT_EMIT_LOC_STRINGS": "YES",
                "SWIFT_VERSION": "5.0",
                "TARGETED_DEVICE_FAMILY": "1,2",
            },
        ),
        (
            DEBUG_TEST,
            "Debug",
            {
                "BUNDLE_LOADER": "$(TEST_HOST)",
                "CODE_SIGN_STYLE": "Automatic",
                "CURRENT_PROJECT_VERSION": "1",
                "GENERATE_INFOPLIST_FILE": "YES",
                "IPHONEOS_DEPLOYMENT_TARGET": "17.0",
                "MARKETING_VERSION": "0.1.0",
                "PRODUCT_BUNDLE_IDENTIFIER": "io.skyprairie.dockwalk.tests",
                "PRODUCT_NAME": "$(TARGET_NAME)",
                "SWIFT_VERSION": "5.0",
                "TARGETED_DEVICE_FAMILY": "1,2",
                "TEST_HOST": "$(BUILT_PRODUCTS_DIR)/DockWalk.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/DockWalk",
            },
        ),
        (
            RELEASE_TEST,
            "Release",
            {
                "BUNDLE_LOADER": "$(TEST_HOST)",
                "CODE_SIGN_STYLE": "Automatic",
                "CURRENT_PROJECT_VERSION": "1",
                "GENERATE_INFOPLIST_FILE": "YES",
                "IPHONEOS_DEPLOYMENT_TARGET": "17.0",
                "MARKETING_VERSION": "0.1.0",
                "PRODUCT_BUNDLE_IDENTIFIER": "io.skyprairie.dockwalk.tests",
                "PRODUCT_NAME": "$(TARGET_NAME)",
                "SWIFT_VERSION": "5.0",
                "TARGETED_DEVICE_FAMILY": "1,2",
                "TEST_HOST": "$(BUILT_PRODUCTS_DIR)/DockWalk.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/DockWalk",
            },
        ),
    ]:
        w(f"\t\t{cfg_id} /* {name} */ = {{")
        w("\t\t\tisa = XCBuildConfiguration;")
        w(f"\t\t\tname = {name};")
        w("\t\t\tbuildSettings = {")
        for k, v in settings.items():
            w(f"\t\t\t\t{k} = {v};")
        w("\t\t\t};")
        w("\t\t};")
    w("/* End XCBuildConfiguration section */")

    w("\n/* Begin XCConfigurationList section */")
    xcconfig_list(CONFIG_LIST_PROJ, 'PBXProject "DockWalk"', DEBUG_PROJ, RELEASE_PROJ)
    xcconfig_list(CONFIG_LIST_APP, 'PBXNativeTarget "DockWalk"', DEBUG_APP, RELEASE_APP)
    xcconfig_list(
        CONFIG_LIST_TEST, 'PBXNativeTarget "DockWalkTests"', DEBUG_TEST, RELEASE_TEST
    )
    w("/* End XCConfigurationList section */")

    w("\t};")
    w(f"\trootObject = {PROJ} /* Project object */;")
    w("}")

    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"Wrote {OUT} ({len(swift_files)} app sources, {len(test_files)} tests)")


if __name__ == "__main__":
    main()
