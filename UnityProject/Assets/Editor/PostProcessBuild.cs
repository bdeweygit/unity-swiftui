using UnityEditor;
using UnityEditor.iOS.Xcode;

/* We could implement UnityEditor.Build.IPostprocessBuildWithReport interface
   but documentation is unclear if this is preferred over the below callback attribute.
   There is a known bug with the interface's BuildReport having wrong information, so we opt to use the attribute. */
public class PostProcessBuild
{
    [UnityEditor.Callbacks.PostProcessBuildAttribute]
    public static void OnPostProcessBuild(BuildTarget target, string buildPath)
    {
        /* Edit Unity generated Xcode project to enable Unity as a library:
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

            /* Add custom modulemap for NativeState plugin
               interop with Swift and set corresponding build setting:
               developer.apple.com/documentation/xcode/build-settings-reference#Module-Map-File */
            string modulemapRelativePath = "UnityFramework/UnityFramework.modulemap";
            string modulemapAbsolutePath = $"{buildPath}/{modulemapRelativePath}";
            FileUtil.ReplaceFile("Assets/Plugins/iOS/UnityFramework.modulemap", modulemapAbsolutePath);
            project.AddFile(modulemapAbsolutePath, modulemapRelativePath);
            project.AddBuildProperty(unityFrameworkTargetGuid, "MODULEMAP_FILE", modulemapRelativePath);

            // Overwrite project
            project.WriteToFile(projectPath);
        }
    }
}
