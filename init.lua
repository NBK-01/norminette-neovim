require("nbk.plugins-setup")
require("nbk.plugins.gitsigns")
require("nbk.core.options")
require("nbk.core.keymaps")
require("nbk.core.colorscheme")
require("nbk.plugins.nvim-tree")
require("nbk.plugins.comment")
require("nbk.plugins.lualine")
require("nbk.plugins.telescope")
require("nbk.plugins.nvim-cmp")
require("nbk.plugins.autopairs")
require("nbk.plugins.treesitter")

-- Highlight trailing whitespace and lines longer than 80 columns
--vim.cmd('highlight LongLine ctermbg=DarkYellow guibg=#A52A2A')
--vim.cmd('highlight WhitespaceEOL ctermbg=DarkYellow guibg=#A52A2A')

-- Autocommands for managing highlights
--vim.cmd([[
  --augroup MyHighlightGroup
    --autocmd!
    --" Highlight long lines (>80 characters)
    --autocmd BufWinEnter * call matchadd('LongLine', '\%>80v.\+', -1)

    --" Highlight trailing whitespace at the end of lines
    --autocmd InsertEnter * call matchdelete(w:m1)
    --autocmd InsertEnter * let w:m2 = matchadd('WhitespaceEOL', '\s\+\%#\@<!$', -1)
    --autocmd InsertLeave * call matchdelete(w:m2)
    --autocmd InsertLeave * let w:m1 = matchadd('WhitespaceEOL', '\s\+$', -1)
  --augroup END
--]])

-- Enable filetype detection
vim.cmd('filetype on')

-- C/C++ programming helpers
vim.cmd([[
  augroup csrc
    au!
    autocmd FileType * set nocindent smartindent
    autocmd FileType c,cpp set cindent
  augroup END
]])

-- Set a few indentation parameters
vim.o.cinoptions = ':0,g0,(0,Ws,l1'
vim.o.smarttab = true

-- Highlight syntax in programming languages
-- Handle Makefiles
vim.cmd([[
  augroup filetype
    au! BufRead,BufNewFile *Makefile* set filetype=make
  augroup END
]])

-- In Makefiles, don't expand tabs to spaces
vim.cmd('autocmd FileType make set noexpandtab')

-- Clang code-completion support
vim.g.clang_path = "clang++"
vim.g.clang_opts = {
  "-x", "c++",
  "-D__STDC_LIMIT_MACROS=1", "-D__STDC_CONSTANT_MACROS=1",
  "-Iinclude"
}

function ClangComplete(findstart, base)
  if findstart == 1 then
    local line = vim.fn.getline('.')
    local start = vim.fn.col('.') - 1
    while start > 0 and line:sub(start, start):match('%w') do
      start = start - 1
    end
    return start
  end

  local l = vim.fn.line('.')
  local c = vim.fn.col('.')
  local the_command = string.format('%s -cc1 -code-completion-at=-:%d:%d', vim.g.clang_path, l, c)
  for _, opt in ipairs(vim.g.clang_opts) do
    the_command = the_command .. ' ' .. opt
  end

  local process_input = table.concat(vim.fn.getline(1, l), "\n") .. " "
  local input_lines = vim.fn.split(vim.fn.system(the_command, process_input), "\n")

  for _, input_line in ipairs(input_lines) do
    if input_line:sub(1, 11) == 'COMPLETION: ' then
      local value = input_line:sub(12)

      local spacecolonspace = string.find(value, " : ")
      local menu = ""
      if spacecolonspace then
        menu = value:sub(spacecolonspace + 3)
        value = value:sub(1, spacecolonspace - 1)
      end

      local hidden = string.find(value, " (Hidden)")
      if hidden then
        menu = menu .. " (Hidden)"
        value = value:sub(1, hidden - 1)
      end

      if value == "Pattern" then
        value = menu
        local pound = string.find(value, "#")
        if pound then
          value = value:sub(1, pound - 2)
        end
      end

      if base ~= "" and not value:startswith(base) then
        goto continue
      end

      vim.fn.complete_add({
        word = value,
        menu = menu,
        info = input_line,
        dup = 1
      })

      if vim.fn.complete_check() then
        return {}
      end
    elseif input_line:sub(1, 9) == "OVERLOAD: " then
      local value = input_line:sub(10)
      vim.fn.complete_add({
        word = " ",
        menu = value,
        info = input_line,
        dup = 1
      })

      if vim.fn.complete_check() then
        return {}
      end
    end

    ::continue::
  end

  return {}
end

-- Enable Clang-based autocompletion
vim.o.omnifunc = 'v:lua.ClangComplete'

-- Additional features (optional)
--vim.o.showcmd = true
--vim.o.showmatch = true
--vim.o.showmode = true
--vim.o.incsearch = true
--vim.o.ruler = true

-- Enable syntax highlighting for specific file types
vim.cmd([[
  augroup filetype
    au! BufRead,BufNewFile *.ll set filetype=llvm
    au! BufRead,BufNewFile *.td set filetype=tablegen
    au! BufRead,BufNewFile *.rst set filetype=rest
  augroup END
]])
