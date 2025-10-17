package main

import (
	"errors"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"syscall"
)

var candidateDirs = []string{
	"/home/linuxbrew/.linuxbrew/bin",
	"/opt/homebrew/bin",
}

func main() {
	nuPath, dir, err := findNu()
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}

	if err := execNu(nuPath, dir); err != nil {
		printExecErr(err)
	}
}

func findNu() (string, string, error) {
	for _, dir := range candidateDirs {
		nuPath := filepath.Join(dir, "nu")
		info, err := os.Stat(nuPath)
		if err != nil {
			continue
		}

		if info.Mode().IsRegular() && info.Mode()&0111 != 0 {
			return nuPath, dir, nil
		}
	}

	return "", "", errors.New("nu executable not found in known locations")
}

func execNu(nuPath, dir string) error {
	env, err := buildEnv(dir)
	if err != nil {
		return err
	}

	fmt.Println(nuPath, os.Args[1:])

	cmd := exec.Command(nuPath, os.Args[1:]...)
	cmd.Env = env
	cmd.Stdin = os.Stdin
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr

	return cmd.Run()
}

func buildEnv(dir string) ([]string, error) {
	env := envToMap(os.Environ())

	pathValue := dir
	if existing, ok := env["PATH"]; ok && existing != "" {
		pathValue = strings.Join([]string{dir, existing}, string(os.PathListSeparator))
	}
	env["PATH"] = pathValue

	home := env["HOME"]
	if home == "" {
		var err error
		home, err = os.UserHomeDir()
		if err != nil {
			return nil, fmt.Errorf("determine home directory: %w", err)
		}
	}
	env["XDG_CONFIG_HOME"] = filepath.Join(home, ".config")

	return mapToEnv(env), nil
}

func envToMap(environ []string) map[string]string {
	env := make(map[string]string, len(environ))
	for _, entry := range environ {
		parts := strings.SplitN(entry, "=", 2)
		if len(parts) != 2 {
			continue
		}

		key := parts[0]
		val := parts[1]
		env[key] = val
	}

	return env
}

func mapToEnv(values map[string]string) []string {
	env := make([]string, 0, len(values))
	for key, val := range values {
		env = append(env, fmt.Sprintf("%s=%s", key, val))
	}

	return env
}

func printExecErr(err error) {
	if exitErr, ok := err.(*exec.ExitError); ok {
		if status, ok := exitErr.Sys().(syscall.WaitStatus); ok {
			os.Exit(status.ExitStatus())
		}
	}

	fmt.Fprintln(os.Stderr, err)
	os.Exit(1)
}
