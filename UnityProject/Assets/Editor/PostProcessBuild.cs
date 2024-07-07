using UnityEditor;
using UnityEditor.iOS.Xcode;

public class PostProcessBuild
{
    [UnityEditor.Callbacks.PostProcessBuildAttribute]
    public static void OnPostprocessBuild(BuildTarget target, string buildPath)
    {
        /* Edit Unity Xcode project to enable Unity as a library:
           github.com/Unity-Technologies/uaal-example/blob/master/docs/ios.md */
        if (target == BuildTarget.iOS)
        {
            // Read project
            string projectPath = PBXProject.GetPBXProjectPath(buildPath);
            PBXProject project = new PBXProject();
            project.ReadFromFile(projectPath);

            // Get main and framework target guids
            string unityMainTargetGuid = project.GetUnityMainTargetGuid();
            string unityFrameworkTargetGuid = project.GetUnityFrameworkTargetGuid();

            // Set NativeState plugin header visibility to public
            string pluginHeaderGuid = project.FindFileGuidByProjectPath("Libraries/Plugins/iOS/NativeState.h");
            project.AddPublicHeaderToBuild(unityFrameworkTargetGuid, pluginHeaderGuid);

            // Change data directory target membership to framework only
            string dataDirectoryGuid = project.FindFileGuidByProjectPath("Data");
            project.RemoveFileFromBuild(unityMainTargetGuid, dataDirectoryGuid);
            project.AddFileToBuild(unityFrameworkTargetGuid, dataDirectoryGuid);

            // Add custom modulemap for NativeState plugin integration with Swift
            string modulemapRelativePath = "UnityFramework/UnityFramework.modulemap";
            string modulemapAbsolutePath = $"{buildPath}/{modulemapRelativePath}";
            FileUtil.CopyFileOrDirectory("Assets/Plugins/iOS/UnityFramework.modulemap", modulemapAbsolutePath);
            project.AddFile(modulemapAbsolutePath, modulemapRelativePath);
            project.AddBuildProperty(unityFrameworkTargetGuid, "MODULEMAP_FILE", modulemapRelativePath);

            // Overwrite project
            project.WriteToFile(projectPath);
        }
    }
}
