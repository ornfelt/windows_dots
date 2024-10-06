-- Automatic command to adjust format options
vim.cmd [[
  autocmd FileType * setlocal formatoptions-=c formatoptions-=r formatoptions-=o
]]

-- vim.api.nvim_command('autocmd BufEnter *.tex :set wrap linebreak nolist spell')

-- Automatically load the session when entering vim
-- vim.api.nvim_create_autocmd("VimEnter", {
--   pattern = "*",
--   command = "source ~/.vim/sessions/s.vim"
-- })

-- Helper function to create key mappings for given filetypes
local function create_mappings(ft, mappings)
  vim.api.nvim_create_autocmd("FileType", {
    pattern = ft,
    callback = function()
      local bufnr = vim.api.nvim_get_current_buf()
      for lhs, rhs in pairs(mappings) do
        vim.api.nvim_buf_set_keymap(bufnr, 'i', lhs, rhs, { noremap = true, silent = true })
      end
    end
  })
end

-- Text
create_mappings("vtxt,vimwiki,wiki,text", {
  ["line<Tab>"] = '----------------------------------------------------------------------------------<Enter>',
  ["oline<Tab>"] = '******************************************<Enter>',
  ["date<Tab>"] = '<-- <C-R>=strftime("%Y-%m-%d %a")<CR><Esc>A -->'
})

-- SQL
create_mappings("sql", {
  ["fun<Tab>"] = 'delimiter //<Enter>create function x ()<Enter>returns int<Enter>no sql<Enter>begin<Enter><Enter><Enter>end //<Enter>delimiter ;<Esc>/x<Enter>GN',
  ["pro<Tab>"] = 'delimiter //<Enter>create procedure x ()<Enter>begin<Enter><Enter><Enter>end //<Enter>delimiter ;<Esc>/x<Enter>GN',
  ["vie<Tab>"] = 'create view x as<Enter>select <Esc>/x<Enter>GN'
})

-- HTML
create_mappings("html", {
  ["<i<Tab>"] = '<em></em> <Space><++><Esc>/<<Enter>GNi',
  ["<b<Tab>"] = '<b></b><Space><++><Esc>/<<Enter>GNi',
  ["<h1<Tab>"] = '<h1></h1><Space><++><Esc>/<<Enter>GNi',
  ["<h2<Tab>"] = '<h2></h2><Space><++><Esc>/<<Enter>GNi',
  ["<im<Tab>"] = '<img></img><Space><++><Esc>/<<Enter>GNi'
})

-- C
create_mappings("c", {
  ["sout<Tab>"] = 'printf("x: %s\\n", x);<Esc>Fxciw',
  ["for<Tab>"] = 'for(int i = 0; i < val; i++){<Enter><Enter>}<Esc>?val<Enter>ciw',
  ["fore<Tab>"] = 'for (int i = 0; i < length; i++) {<Enter>printf("El: %d\\n", arr[i]);<Enter>}<Esc>?arr<Enter>ciw'
})

-- C++
create_mappings("cpp,c++", {
  ["sout<Tab>"] = 'std::cout << "x: " << x << std::endl;<Esc>Fxciw',
  ["for<Tab>"] = 'for(int i = 0; i < val; i++){<Enter><Enter>}<Esc>?val<Enter>ciw',
  ["fore<Tab>"] = 'for (auto& el : arr) {<Enter><Enter>}<Esc>?arr<Enter>ciw'
})

-- C#
create_mappings("cs", {
  ["sout<Tab>"] = 'Console.WriteLine($"x: {x}");<Esc>Fxciw',
  ["fore<Tab>"] = 'foreach (var x in obj)<Enter>{<Enter><Enter>}<Esc>?obj<Enter>ciw',
  ["for<Tab>"] = 'for(int i = 0; i < val; i++){<Enter><Enter>}<Esc>?val<Enter>ciw'
})

-- Go
create_mappings("go", {
  ["sout<Tab>"] = 'fmt.Printf("x: %s\\n", x)<Esc>Fxciw',
  ["for<Tab>"] = 'for i := 0; i < val; i++ {<Enter><Enter>}<Esc>?val<Enter>ciw',
  ["fore<Tab>"] = 'for idx, el := range arr {<Enter><Enter>}<Esc>?arr<Enter>ciw'
  -- ["fore<Tab>"] = 'for _, el := range arr {<Enter><Enter>}<Esc>?arr<Enter>ciw'
})

-- Java
create_mappings("java", {
  ["fore<Tab>"] = 'for (String s : obj){<Enter><Enter>}<Esc>?obj<Enter>ciw',
  ["for<Tab>"] = 'for(int i = 0; i < val; i++){<Enter><Enter>}<Esc>?val<Enter>ciw',
  ["sout<Tab>"] = 'System.out.println("");<Esc>?""<Enter>li',
  ["psvm<Tab>"] = 'public static void main(String[] args){<Enter><Enter>}<Esc>?{<Enter>o'
})

-- Js/Ts
create_mappings("js,ts,javascript,typescript", {
  ["sout<Tab>"] = 'console.log(`x: ${x}`);<Esc>Fxciw',
  ["for<Tab>"] = 'for (let i = 0; i < val; i++) {<Enter><Enter>}<Esc>?val<Enter>ciw',
  ["fore<Tab>"] = 'arr.forEach(el => {<Enter><Enter>});<Esc>?arr<Enter>ciw'
})

-- Lua
create_mappings("lua", {
  ["sout<Tab>"] = 'print("x: " .. x)<Esc>Fxciw',
  ["for<Tab>"] = 'for i = 1, val, 1 do<Enter><Enter>end<Esc>?val<Enter>ciw',
  ["fore<Tab>"] = 'for i, el in ipairs(arr) do<Enter><Enter>end<Esc>?arr<Enter>ciw'
})

-- Php
create_mappings("php", {
  ["sout<Tab>"] = 'echo "x: $x\\n";<Esc>Fxciw',
  ["for<Tab>"] = 'for ($i = 0; $i < $val; $i++) {<Enter><Enter>}<Esc>?val<Enter>ciw',
  ["fore<Tab>"] = 'foreach ($arr as $el) {<Enter><Enter>}<Esc>?arr<Enter>ciw'
})

-- Python
create_mappings("py,python", {
  ["sout<Tab>"] = 'print(f"x: {x}");<Esc>Fxciw',
  ["for<Tab>"] = 'for i in range():<Esc>hi',
  ["fore<Tab>"] = 'for i in :<Esc>i'
})

-- Rust
create_mappings("rs,rust", {
  ["sout<Tab>"] = 'println!("x: {}", x);<Esc>Fxciw',
  ["for<Tab>"] = 'for i in 0..val {<Enter><Enter>}<Esc>?val<Enter>ciw',
  ["fore<Tab>"] = 'for el in arr.iter() {<Enter><Enter>}<Esc>?arr<Enter>ciw'
})

local function run_pdflatex()
    local file = vim.fn.expand('%:p')
    vim.fn.jobstart({'pdflatex', file})
end

-- Set up autocommand to run pdflatex on write for .tex files
if vim.fn.executable('pdflatex') == 1 then
    vim.api.nvim_create_autocmd('BufWritePost', {
    pattern = '*.tex',
    callback = run_pdflatex,
    })
end

vim.api.nvim_create_autocmd("BufRead", {
    -- pattern = "*",
    pattern = {"*.txt", "*.sql"},
    callback = function()
        vim.cmd('edit ++ff=dos %')
    end
})

