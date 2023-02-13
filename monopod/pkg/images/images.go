package images

import (
	"fmt"
	"os"
	"path"
	"path/filepath"
	"strings"

	"gopkg.in/yaml.v3"

	"github.com/chainguard-images/images/monopod/pkg/constants"
)

type Image struct {
	ImageName                   string `json:"imageName"`
	ImageStatus                 string `json:"imageStatus"`
	ImageSummaryJson            string `json:"imageSummaryJson"`
	MelangeConfig               string `json:"melangeConfig"`
	MelangeArchs                string `json:"melangeArchs"`
	MelangeTemplate             string `json:"melangeTemplate"`
	MelangeEmptyWorkspace       bool   `json:"melangeEmptyWorkspace"`
	MelangeWorkdir              string `json:"melangeWorkdir"`
	ApkoConfig                  string `json:"apkoConfig"`
	ApkoKeyringAppend           string `json:"apkoKeyringAppend"`
	ApkoRepositoryAppend        string `json:"apkoRepositoryAppend"`
	ApkoAdditionalTags          string `json:"apkoAdditionalTags"`
	ApkoBaseTag                 string `json:"apkoBaseTag"`
	ApkoTargetTag               string `json:"apkoTargetTag"`
	ApkoPackageVersionTag       string `json:"apkoPackageVersionTag"`
	ApkoPackageVersionTagPrefix string `json:"apkoPackageVersionTagPrefix"`
	TestCommandExe              string `json:"testCommandExe"`
	TestCommandDir              string `json:"testCommandDir"`
	ExcludeTags                 string `json:"excludeTags"`
}

type ImageManifest struct {
	Ref      string                 `yaml:"ref"`
	Status   string                 `yaml:"status"`
	Variants []ImageManifestVariant `yaml:"versions"`
}

type ImageManifestVariant struct {
	Apko    ImageManifestVariantApko    `yaml:"apko"`
	Melange ImageManifestVariantMelange `yaml:"melange"`
}

type ImageManifestVariantApko struct {
	Config          string                                  `yaml:"config"`
	ExtractTagsFrom ImageManifestVariantApkoExtractTagsFrom `yaml:"extractTagsFrom"`
	Tags            []string                                `yaml:"tags"`
}

type ImageManifestVariantMelange struct {
	Configs []string `yaml:"configs"`
	Mount   bool     `yaml:"mount"`
}

type ImageManifestVariantApkoExtractTagsFrom struct {
	Package string   `yaml:"package"`
	Prefix  string   `yaml:"prefix"`
	Exclude []string `yaml:"exclude"`
}

// Our miniature schema of the Apko manifest so we dont have to import it here
type ApkoManifest struct {
	Archs []string `yaml:"archs"`
}

func ListAll() ([]Image, error) {
	allImages := []Image{}
	imageDirs, err := os.ReadDir(constants.ImagesDirName)
	if err != nil {
		return nil, err
	}
	seen := map[string]bool{}
	for _, imageDir := range imageDirs {
		if !imageDir.IsDir() {
			continue
		}
		imageName := imageDir.Name()
		imageManifestFilename := filepath.Join(constants.ImagesDirName, imageName, constants.ImageManifestFilename)
		b, err := os.ReadFile(imageManifestFilename)
		if err != nil {
			return nil, err
		}
		var m ImageManifest
		if err := yaml.Unmarshal(b, &m); err != nil {
			return nil, err
		}
		imageStatus := m.Status
		if imageStatus == "" {
			imageStatus = constants.DefaultImageStatus
		}
		for _, variant := range m.Variants {
			apkoConfig := filepath.Join(constants.ImagesDirName, imageName, variant.Apko.Config)
			apkoTargetTag := strings.Replace(filepath.Base(apkoConfig), constants.ApkoYamlFileExtension, "", 1)
			apkoAdditionalTags := strings.Join(variant.Apko.Tags, ",")

			// Ensure that we dont have duplicate entries for any image/variant combo
			seenKey := fmt.Sprintf("%s--%s", imageName, apkoTargetTag)
			if _, ok := seen[seenKey]; ok {
				return nil, fmt.Errorf("more than one variant with image=%s tag=%s", imageName, apkoTargetTag)
			}
			seen[seenKey] = true

			testCommandExe := ""
			testCommandDir := ""
			testScriptFilename := filepath.Join(constants.ImagesDirName, imageName, constants.DefaultTestScriptFilename)
			testScriptsDirname := filepath.Join(constants.ImagesDirName, imageName, constants.DefaultTestDirname)
			if _, err := os.Stat(testScriptsDirname); err == nil {
				// For loop to run all the .sh files found in the tests/ directory
				testCommandExe = fmt.Sprintf("(set -ex; for x in $(find %s -mindepth 1 -name '*.sh'); do ./$x; done)", constants.DefaultTestDirname)
				testCommandDir = filepath.Join(constants.ImagesDirName, imageName)
			} else if _, err := os.Stat(testScriptFilename); err == nil {
				testCommandExe = fmt.Sprintf("./%s", constants.DefaultTestScriptFilename)
				testCommandDir = filepath.Join(constants.ImagesDirName, imageName)
			}

			var apkoBaseTag string
			if m.Ref != "" {
				apkoBaseTag = m.Ref
			} else {
				apkoBaseTag = path.Join(constants.DefaultRegistry, imageName)
			}

			melangeConfig := ""
			melangeArchs := ""
			apkoKeyringAppend := ""
			apkoRepositoryAppend := ""

			// If non-empty workspace for melange build, specify
			// the image dir as the workdir for melange build
			melangeWorkdir := ""
			melangeEmptyWorkspace := true
			if variant.Melange.Mount {
				melangeEmptyWorkspace = false
				melangeWorkdir = filepath.Join(constants.ImagesDirName, imageName)
			}

			melangeConfigs := variant.Melange.Configs
			if len(melangeConfigs) > 0 {
				apkoKeyringAppend = constants.DefaultApkoKeyringAppend
				apkoRepositoryAppend = constants.DefaultApkoRepositoryAppend
				var a ApkoManifest
				b, err := os.ReadFile(apkoConfig)
				if err != nil {
					return nil, err
				}
				if err := yaml.Unmarshal(b, &a); err != nil {
					return nil, err
				}
				melangeArchs = strings.Join(a.Archs, ",")
				tmp := []string{}
				for _, config := range melangeConfigs {
					if melangeEmptyWorkspace {
						tmp = append(tmp, filepath.Join(constants.ImagesDirName, imageName, config))
					} else {
						tmp = append(tmp, config)
					}
				}
				melangeConfig = strings.Join(tmp, ",")
			}

			i := Image{
				ImageName:                   imageName,
				ImageStatus:                 imageStatus,
				ImageSummaryJson:            "",
				MelangeConfig:               melangeConfig, // TODO
				MelangeArchs:                melangeArchs,  // TODO
				MelangeTemplate:             "",            // TODO
				MelangeEmptyWorkspace:       melangeEmptyWorkspace,
				MelangeWorkdir:              melangeWorkdir,
				ApkoConfig:                  apkoConfig,
				ApkoKeyringAppend:           apkoKeyringAppend,
				ApkoRepositoryAppend:        apkoRepositoryAppend,
				ApkoBaseTag:                 apkoBaseTag,
				ApkoTargetTag:               apkoTargetTag,
				ApkoAdditionalTags:          apkoAdditionalTags,
				ApkoPackageVersionTag:       variant.Apko.ExtractTagsFrom.Package,
				ApkoPackageVersionTagPrefix: variant.Apko.ExtractTagsFrom.Prefix,
				TestCommandExe:              testCommandExe,
				TestCommandDir:              testCommandDir,
				ExcludeTags:                 strings.Join(variant.Apko.ExtractTagsFrom.Exclude, ","),
			}
			allImages = append(allImages, i)
		}
	}
	return allImages, nil
}
