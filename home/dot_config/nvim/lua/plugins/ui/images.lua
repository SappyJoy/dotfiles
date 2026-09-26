-- Conditionally disable this plugin if running inside VSCode Neovim integration,
-- as VSCode typically handles image rendering itself.
-- Assumes `vim.g.vscode = true` is set by the VSCode extension.
if vim.g.vscode then
  return {} -- Return empty table to disable all plugins in this file
end

-- Plugin for displaying images directly within Neovim buffers
return {
  {
    '3rd/image.nvim',
    -- Load when needed, e.g., when opening markdown or specific image files
    -- Or load late if image viewing isn't a primary startup activity
    event = 'VeryLazy',
    -- Alternatively, load on specific filetypes:
    -- ft = { "markdown", "png", "jpg", "jpeg", "gif" },
    opts = {
      -- Choose the backend for image display. 'kitty' works with Kitty terminal.
      -- Other options include 'ueberzug', 'viu'. 'auto' tries to detect.
      backend = 'kitty',
      -- Integration with other plugins/filetypes
      integrations = {
        markdown = {
          -- filetypes = { 'markdown', 'quarto' }, -- markdown extensions (ie. quarto) can go here
          enabled = true, -- Enable image display in markdown files
          clear_in_insert_mode = false, -- Keep images visible when entering insert mode
          download_remote_images = true, -- Attempt to download and display http(s) images
          only_render_image_at_cursor = true, -- Only render the image under/near the cursor (improves performance)
        },
        -- neorg = {
        --   enabled = true,
        --   clear_in_insert_mode = false,
        --   download_remote_images = false,
        --   only_render_image_at_cursor = false,
        --   filetypes = { 'norg' },
        -- },
        -- Add other integrations if needed (e.g., neorg, telescope)
        -- telescope = { enabled = true },
      },
      -- Set maximum image size as a percentage of the Neovim window size.
      -- Setting to math.huge attempts to use the image's original size, constrained by the window.
      -- Consider setting a specific limit like 90 (%) if `math.huge` causes layout issues.
      max_height_window_percentage = math.huge,
      max_width_window_percentage = math.huge,

      -- Filetypes of floating windows that should NOT cause images underneath to be cleared.
      -- Useful for completion menus, documentation popups etc.
      window_overlap_clear_ft_ignore = { 'cmp_menu', 'cmp_docs', 'lspinfo', 'notify', '' }, -- Added lspinfo, notify
      window_overlap_clear_enabled = true, -- toggles images when windows are overlapped
      editor_only_render_when_focused = true, -- auto show/hide images when the editor gains/looses focus
      tmux_show_only_in_active_window = true, -- auto show/hide images in the correct Tmux window (needs visual-activity off)
      -- Other options:
      -- window_overlap_clear_enabled = true, -- Clear images obscured by floats (default)
      -- editor_only_render_when_active = true, -- Render only when Neovim window is focused
      -- hijack_file_patterns = { "*.png", "*.jpg", "*.jpeg", "*.gif" } -- Files to open with image.nvim by default
    },
    -- No explicit config function needed if only using opts
  },
}
