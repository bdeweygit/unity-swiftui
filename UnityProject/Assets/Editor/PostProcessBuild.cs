using UnityEngine;
using UnityEditor;
using UnityEditor.Callbacks;
using UnityEditor.iOS.Xcode;

public class PostProcessBuild
{
    [PostProcessBuildAttribute]
    public static void OnPostprocessBuild(BuildTarget target, string buildPath)
    {
        if (target == BuildTarget.iOS)
        {
            string pbxPath = PBXProject.GetPBXProjectPath(buildPath);
            PBXProject pbx = new PBXProject();
            pbx.ReadFromFile(pbxPath);

            string dataDirectoryXcodePath = "Data";
            string pluginHeaderXcodePath = "Libraries/Plugins/iOS/NativeState.h";
            string modulemapXcodePath = "UnityFramework/UnityFramework.modulemap";
            string modulemapUnityPath = "Assets/Plugins/iOS/UnityFramework.modulemap";
            string modulemapDestinationPath = $"{buildPath}/{modulemapXcodePath}";
            string modulemapBuildPropertyName = "MODULEMAP_FILE";
            string unityMainTargetGuid = pbx.GetUnityMainTargetGuid();
            string unityFrameworkTargetGuid = pbx.GetUnityFrameworkTargetGuid();
            string dataDirectoryGuid = pbx.FindFileGuidByProjectPath(dataDirectoryXcodePath);
            string pluginHeaderGuid = pbx.FindFileGuidByProjectPath(pluginHeaderXcodePath);

            FileUtil.CopyFileOrDirectory(modulemapUnityPath, modulemapDestinationPath);
            pbx.AddFile(modulemapDestinationPath, modulemapXcodePath);
            pbx.AddBuildProperty(unityFrameworkTargetGuid, modulemapBuildPropertyName, modulemapXcodePath);
            pbx.RemoveFileFromBuild(unityMainTargetGuid, dataDirectoryGuid);
            pbx.AddFileToBuild(unityFrameworkTargetGuid, dataDirectoryGuid);
            pbx.AddPublicHeaderToBuild(unityFrameworkTargetGuid, pluginHeaderGuid);

            pbx.WriteToFile(pbxPath);
        }
    }
}
