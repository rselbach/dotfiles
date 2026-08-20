-- Parallels reports the top-left accent key as the ISO <LSGT> key.
hl.config({
  input = {
    kb_file = os.getenv("HOME") .. "/.config/hypr/xkb/parallels.xkb",
  },
})
