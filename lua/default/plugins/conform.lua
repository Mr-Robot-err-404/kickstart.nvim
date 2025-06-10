return { -- Autoformat
  'stevearc/conform.nvim',
  event = { 'BufWritePre' },
  cmd = { 'ConformInfo' },
  keys = {
    {
      '<leader>f',
      function()
        require('conform').format { async = true, lsp_format = 'fallback' }
      end,
      mode = '',
      desc = '[F]ormat buffer',
    },
  },
  opts = {},
  config = function()
    local conform = require 'conform'

    -- Function to determine formatters based on project files
    local function get_javascript_formatter()
      -- Check for biome.json in the project root
      local has_biome = vim.fn.filereadable(vim.fn.getcwd() .. '/biome.json') == 1

      -- Check for prettier config files
      local prettier_configs = {
        '.prettierrc',
        '.prettierrc.js',
        '.prettierrc.json',
        '.prettierrc.yml',
        '.prettierrc.yaml',
        'prettier.config.js',
        'prettier.config.cjs',
      }

      local has_prettier = false
      for _, config in ipairs(prettier_configs) do
        if vim.fn.filereadable(vim.fn.getcwd() .. '/' .. config) == 1 then
          has_prettier = true
          break
        end
      end

      -- Prioritize based on found config files
      if has_biome and not has_prettier then
        return { 'biome-check' }
      elseif has_prettier and not has_biome then
        return { 'prettierd, prettier' }
      else
        -- If both or none are found, prefer prettierd then biome as fallback
        return { 'prettierd', 'prettier', 'biome-check' }
      end
    end

    -- Get formatters when setting up
    local js_formatters = get_javascript_formatter()

    conform.setup {
      formatters_by_ft = {
        lua = { 'stylua' },
        javascript = { 'prettier' },
        json = { 'prettier' },
        jsonc = { 'prettier' },
        javascriptreact = { 'prettier' },
        typescript = { 'prettier' },
        typescriptreact = { 'prettier' },
        css = js_formatters,
        html = js_formatters,
        yaml = { 'prettier' },
        go = { 'gofmt', 'goimports' },
        markdown = { 'prettier' },
      },
      notify_on_error = false,
      format_on_save = function(bufnr)
        -- Disable "format_on_save lsp_fallback" for languages that don't
        -- have a well standardized coding style. You can add additional
        -- languages here or re-enable it for the disabled ones.
        local disable_filetypes = { c = true, cpp = true, dart = true }
        if disable_filetypes[vim.bo[bufnr].filetype] then
        else
          return {
            timeout_ms = 500,
            lsp_format = 'fallback',
          }
        end
        return nil
      end,
    }
    -- Update formatters when changing directories
    vim.api.nvim_create_autocmd({ 'DirChanged' }, {
      pattern = '*',
      callback = function()
        local new_js_formatters = get_javascript_formatter()
        local js_filetypes = {
          'javascript',
          'json',
          'jsonc',
          'javascriptreact',
          'typescript',
          'typescriptreact',
          'css',
          'html',
          'yaml',
        }
        for _, ft in ipairs(js_filetypes) do
          conform.formatters_by_ft[ft] = new_js_formatters
        end
      end,
    })
  end,
}
