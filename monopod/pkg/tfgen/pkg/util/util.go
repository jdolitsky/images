package util

import (
	"fmt"
	"os"
	"path"
	"strconv"
	"strings"

	"github.com/chainguard-images/images/monopod/pkg/tfgen/pkg/constants"
	"github.com/google/go-cmp/cmp"
	"github.com/jdolitsky/tq/pkg/tq"
)

func EmptyTerraformFile() *tq.TerraformFile {
	return &tq.TerraformFile{
		Body: tq.TerraformFileBody{
			Blocks: []tq.TerraformFileBlock{},
		},
	}
}

func LoadAllTerraformFilesInDir(dir string) (map[string]*tq.TerraformFile, error) {
	result := map[string]*tq.TerraformFile{}
	entries, err := os.ReadDir(dir)
	if err != nil {
		return nil, err
	}
	for _, entry := range entries {
		if entry.IsDir() {
			continue
		}
		name := entry.Name()
		if strings.HasSuffix(name, constants.TfFileExtension) || strings.HasSuffix(name, constants.TfTemplateFileExtention) {
			b, err := os.ReadFile(path.Join(dir, name))
			if err != nil {
				return nil, err
			}
			tfFile, err := tq.ParseTerraform(b)
			if err != nil {
				return nil, err
			}
			result[name] = tfFile
		}
	}
	return result, nil
}

func ShouldOverwrite(origFilename string, newContent []byte) bool {
	origContent, _ := os.ReadFile(origFilename)
	diff := cmp.Diff(origContent, newContent)
	return diff != ""
}

func TerraformFileToBytes(tfFile *tq.TerraformFile) []byte {
	return []byte(fmt.Sprintf("%s\n\n%s\n", constants.GeneratedTfHeader, tfFile))
}

// tq values are double-quoted due to serialization format
func UnquoteTQString(s string) string {
	return strings.Trim(s, `"`)
}

func QuoteTQString(s string) string {
	return strconv.Quote(s)
}