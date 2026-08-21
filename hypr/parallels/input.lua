-- Parallels reports the top-left accent key as the ISO <LSGT> key.
hl.config({
	input = {
		kb_layout = "us",
		kb_options = "compose:caps,shift:both_capslock_cancel,grp:alts_toggle",

		-- Use a specific keyboard variant if needed (e.g. intl for international keyboards).
		kb_variant = "intl",
		kb_file = os.getenv("HOME") .. "/.config/hypr/xkb/parallels.xkb",
		repeat_delay = 500,
	},
})
