package commands

import (
	"context"
	"fmt"
	"os"

	"github.com/hashicorp/hcl/v2"
	"github.com/hashicorp/hcl/v2/hclwrite"
	"github.com/minamijoyo/tfupdate/tfupdate"
	"github.com/spf13/afero"
	"github.com/spf13/cobra"
)

const (
	terraformLockFilename = ".terraform.lock.hcl"
)

var (
	defaultPlatforms = []string{
		"darwin_arm64",
		"darwin_amd64",
		"linux_amd64",
		//"windows_amd64",
	}
)

type tfupdateOptions struct {
	platforms []string
}

func TfUpdate() *cobra.Command {
	o := &tfupdateOptions{}
	tfupdateCmd := &cobra.Command{
		Use:   "tfupdate",
		Short: "tfupdate recursively updates all .terraform.lock.hcl files for all platforms",
		RunE: func(cmd *cobra.Command, args []string) error {
			return o.runTfUpdate(cmd.Context())
		},
	}
	tfupdateCmd.Flags().StringArrayVarP(&o.platforms, "platform", "", defaultPlatforms, "list of platforms to use")
	return tfupdateCmd
}

/*
func getHashOfZip(zipFilePath string) (string, error) {
	return dirhash.HashZip(zipFilePath, dirhash.Hash1)
}
*/

func (o tfupdateOptions) runTfUpdateOld(ctx context.Context) error {
	aferoFs := afero.NewOsFs()
	lockOption, err := tfupdate.NewOption("lock", "", "", o.platforms, true, []string{})
	if err != nil {
		return err
	}
	gc, err := tfupdate.NewGlobalContext(aferoFs, lockOption)
	if err != nil {
		return err
	}
	mc, err := tfupdate.NewModuleContext(".", gc)
	if err != nil {
		return err
	}
	b, err := afero.ReadFile(aferoFs, terraformLockFilename)
	if err != nil {
		return err
	}
	f, diags := hclwrite.ParseConfig(b, terraformLockFilename, hcl.InitialPos)
	if diags.HasErrors() {
		return fmt.Errorf("hclwrite.ParseConfig(): %s", diags)
	}
	if err := mc.Updater().Update(ctx, mc, terraformLockFilename, f); err != nil {
		return err
	}
	return os.WriteFile(terraformLockFilename, hclwrite.Format(f.Bytes()), 0644)
}
