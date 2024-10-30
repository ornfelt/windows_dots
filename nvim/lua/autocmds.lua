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
  ["sout<Tab>"] = 'SET @x = 42;<Enter>SET @s = "Hello";<Enter>SELECT @x AS x, @s AS s;<Enter>', -- Basic print
  ["souti<Tab>"] = 'SET @intVar = 100;<Enter>SELECT @intVar AS intVar;<Enter>', -- Print integer
  ["souts<Tab>"] = 'SET @strVar = "World";<Enter>SELECT @strVar AS strVar;<Enter>', -- Print string
  ["soutb<Tab>"] = 'SET @boolVar = TRUE;<Enter>SELECT @boolVar AS boolVar;<Enter>', -- Print boolean
  ["soutf<Tab>"] = 'SET @floatVar = 3.14;<Enter>SELECT @floatVar AS floatVar;<Enter>', -- Print float
  ["soutd<Tab>"] = 'SET @doubleVar = 3.14159265359;<Enter>SELECT @doubleVar AS doubleVar;<Enter>', -- Print double
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
  ["sout<Tab>"] = 'printf("");<Esc>?""<Enter>li', -- Basic print
  ["souti<Tab>"] = 'printf("x: %d\\n", x);<Esc>Fxciw', -- Print int
  ["souts<Tab>"] = 'printf("x: %s\\n", x);<Esc>Fxciw', -- Print string
  ["soutb<Tab>"] = 'printf("x: %s\\n", x ? "true" : "false");<Esc>Fxciw', -- Print boolean
  ["soutf<Tab>"] = 'printf("x: %.2f\\n", x);<Esc>Fxciw', -- Print float
  ["soutd<Tab>"] = 'printf("x: %.6f\\n", x);<Esc>Fxciw', -- Print double
  ["soutc<Tab>"] = 'printf("x: %c\\n", x);<Esc>Fxciw', -- Print character
  ["soutp<Tab>"] = 'printf("x: %p\\n", (void*)&x);<Esc>Fxciw', -- Print pointer address
  ["for<Tab>"] = 'for(int i = 0; i < val; i++){<Enter><Enter>}<Esc>?val<Enter>ciw',
  ["fore<Tab>"] = 'for (int i = 0; i < length; i++) {<Enter>printf("El: %d\\n", arr[i]);<Enter>}<Esc>?arr<Enter>ciw'
})

-- C++
create_mappings("cpp,c++", {
  ["sout<Tab>"] = 'std::cout << ""; std::endl;<Esc>?""<Enter>li', -- Basic print
  ["souti<Tab>"] = 'std::cout << "x: " << x << std::endl;<Esc>Fxciw', -- Print int
  ["souts<Tab>"] = 'std::cout << "x: " << x << std::endl;<Esc>Fxciw', -- Print string
  ["soutb<Tab>"] = 'std::cout << "x: " << (x ? "true" : "false") << std::endl;<Esc>Fxciw', -- Print boolean
  ["soutf<Tab>"] = 'std::cout << "x: " << std::fixed << std::setprecision(2) << x << std::endl;<Esc>Fxciw', -- Print float
  ["soutd<Tab>"] = 'std::cout << "x: " << std::fixed << std::setprecision(6) << x << std::endl;<Esc>Fxciw', -- Print double
  ["soutc<Tab>"] = 'std::cout << "x: " << static_cast<char>(x) << std::endl;<Esc>Fxciw', -- Print character
  ["soutp<Tab>"] = 'std::cout << "x: " << &x << std::endl;<Esc>Fxciw', -- Print pointer address
  ["for<Tab>"] = 'for(int i = 0; i < val; i++){<Enter><Enter>}<Esc>?val<Enter>ciw',
  ["fore<Tab>"] = 'for (auto& el : arr) {<Enter><Enter>}<Esc>?arr<Enter>ciw'
})

-- C#
create_mappings("cs", {
  ["sout<Tab>"] = 'Console.WriteLine("");<Esc>?""<Enter>li', -- Basic print
  ["souti<Tab>"] = 'Console.WriteLine($"x: {x}");<Esc>Fxciw', -- Print int
  ["souts<Tab>"] = 'Console.WriteLine($"x: {x}");<Esc>Fxciw', -- Print string
  ["soutb<Tab>"] = 'Console.WriteLine($"x: {x}");<Esc>Fxciw', -- Print boolean
  ["soutf<Tab>"] = 'Console.WriteLine($"x: {x:F2}");<Esc>Fxciw', -- Print float
  ["soutd<Tab>"] = 'Console.WriteLine($"x: {x:F6}");<Esc>Fxciw', -- Print double
  ["soutc<Tab>"] = 'Console.WriteLine($"x: {(char)x}");<Esc>Fxciw', -- Print character
  ["soutp<Tab>"] = 'Console.WriteLine($"x: {x}");<Esc>Fxciw', -- Print pointer (just show the value)
  ["fore<Tab>"] = 'foreach (var x in obj)<Enter>{<Enter><Enter>}<Esc>?obj<Enter>ciw',
  ["for<Tab>"] = 'for(int i = 0; i < val; i++){<Enter><Enter>}<Esc>?val<Enter>ciw'
})

-- Go
create_mappings("go", {
  ["sout<Tab>"] = 'fmt.Println("");<Esc>2F"li', -- Basic print
  ["souti<Tab>"] = 'fmt.Printf("x: %d\\n", x)<Esc>Fxciw', -- Print int
  ["souts<Tab>"] = 'fmt.Printf("x: %s\\n", x)<Esc>Fxciw', -- Print string
  ["soutb<Tab>"] = 'fmt.Printf("x: %t\\n", x)<Esc>Fxciw', -- Print boolean
  ["soutf<Tab>"] = 'fmt.Printf("x: %.2f\\n", x)<Esc>Fxciw', -- Print float
  ["soutd<Tab>"] = 'fmt.Printf("x: %.6f\\n", x)<Esc>Fxciw', -- Print double
  ["soutc<Tab>"] = 'fmt.Printf("x: %c\\n", x)<Esc>Fxciw', -- Print character
  ["soutp<Tab>"] = 'fmt.Printf("x: %p\\n", &x)<Esc>Fxciw', -- Print pointer address
  ["for<Tab>"] = 'for i := 0; i < val; i++ {<Enter><Enter>}<Esc>?val<Enter>ciw',
  ["fore<Tab>"] = 'for idx, el := range arr {<Enter><Enter>}<Esc>?arr<Enter>ciw'
})

-- Java
create_mappings("java", {
  ["sout<Tab>"] = 'System.out.println("");<Esc>?""<Enter>li', -- Basic print
  ["souti<Tab>"] = 'System.out.println("x: " + x);<Esc>Fxciw', -- Print int
  ["souts<Tab>"] = 'System.out.println("x: " + x);<Esc>Fxciw', -- Print string
  ["soutb<Tab>"] = 'System.out.println("x: " + (x ? "true" : "false"));<Esc>Fxciw', -- Print boolean
  ["soutf<Tab>"] = 'System.out.printf("x: %.2f%n", x);<Esc>Fxciw', -- Print float
  ["soutd<Tab>"] = 'System.out.printf("x: %.6f%n", x);<Esc>Fxciw', -- Print double
  ["soutc<Tab>"] = 'System.out.println("x: " + (char)x);<Esc>Fxciw', -- Print character
  ["soutp<Tab>"] = 'System.out.println("x: " + x);<Esc>Fxciw', -- Print pointer (just show the value)
  ["fore<Tab>"] = 'for (String s : obj){<Enter><Enter>}<Esc>?obj<Enter>ciw',
  ["for<Tab>"] = 'for(int i = 0; i < val; i++){<Enter><Enter>}<Esc>?val<Enter>ciw',
  ["psvm<Tab>"] = 'public static void main(String[] args){<Enter><Enter>}<Esc>?{<Enter>o'
})

-- Js/Ts
create_mappings("js,ts,javascript,typescript", {
  ["sout<Tab>"] = 'console.log("");<Esc>?""<Enter>li', -- Basic print
  ["souti<Tab>"] = 'console.log(`x: ${x}`);<Esc>Fxciw', -- Print int
  ["souts<Tab>"] = 'console.log(`x: ${x}`);<Esc>Fxciw', -- Print string
  ["soutb<Tab>"] = 'console.log(`x: ${x}` ? "true" : "false");<Esc>Fxciw', -- Print boolean
  ["soutf<Tab>"] = 'console.log(`x: ${x.toFixed(2)}`);<Esc>Fxciw', -- Print float
  ["soutd<Tab>"] = 'console.log(`x: ${x.toFixed(6)}`);<Esc>Fxciw', -- Print double
  ["soutc<Tab>"] = 'console.log(`x: ${String.fromCharCode(x)}`);<Esc>Fxciw', -- Print character
  ["soutp<Tab>"] = 'console.log(`x: ${x}`);<Esc>Fxciw', -- Print pointer (just show the value)
  ["for<Tab>"] = 'for (let i = 0; i < val; i++) {<Enter><Enter>}<Esc>?val<Enter>ciw',
  ["fore<Tab>"] = 'arr.forEach(el => {<Enter><Enter>});<Esc>?arr<Enter>ciw'
})

-- Lua
create_mappings("lua", {
  ["sout<Tab>"] = 'print("");<Esc>?""<Enter>li', -- Basic print
  ["souti<Tab>"] = 'print("x: " .. x)<Esc>Fxciw', -- Print int
  ["souts<Tab>"] = 'print("x: " .. x)<Esc>Fxciw', -- Print string
  ["soutb<Tab>"] = 'print("x: " .. (x and "true" or "false"))<Esc>Fxciw', -- Print boolean
  ["soutf<Tab>"] = 'print(string.format("x: %.2f", x))<Esc>Fxciw', -- Print float
  ["soutd<Tab>"] = 'print(string.format("x: %.6f", x))<Esc>Fxciw', -- Print double
  ["soutc<Tab>"] = 'print("x: " .. string.char(x))<Esc>Fxciw', -- Print character
  ["soutp<Tab>"] = 'print("x: " .. tostring(x))<Esc>Fxciw', -- Print pointer (just show the value)
  ["for<Tab>"] = 'for i = 1, val, 1 do<Enter><Enter>end<Esc>?val<Enter>ciw',
  ["fore<Tab>"] = 'for i, el in ipairs(arr) do<Enter><Enter>end<Esc>?arr<Enter>ciw'
})

-- Php
create_mappings("php", {
  ["sout<Tab>"] = 'echo "";<Esc>?""<Enter>li', -- Basic print
  ["souti<Tab>"] = 'echo "x: $x\\n";<Esc>Fxciw', -- Print int
  ["souts<Tab>"] = 'echo "x: $x\\n";<Esc>Fxciw', -- Print string
  ["soutb<Tab>"] = 'echo "x: " . ($x ? "true" : "false") . "\\n";<Esc>Fxciw', -- Print boolean
  ["soutf<Tab>"] = 'echo "x: " . number_format($x, 2) . "\\n";<Esc>Fxciw', -- Print float
  ["soutd<Tab>"] = 'echo "x: " . number_format($x, 6) . "\\n";<Esc>Fxciw', -- Print double
  ["soutc<Tab>"] = 'echo "x: " . chr($x) . "\\n";<Esc>Fxciw', -- Print character
  ["soutp<Tab>"] = 'echo "x: " . $x . "\\n";<Esc>Fxciw', -- Print pointer (just show the value)
  ["for<Tab>"] = 'for ($i = 0; $i < $val; $i++) {<Enter><Enter>}<Esc>?val<Enter>ciw',
  ["fore<Tab>"] = 'foreach ($arr as $el) {<Enter><Enter>}<Esc>?arr<Enter>ciw'
})

-- Python
create_mappings("py,python", {
  ["sout<Tab>"] = 'print("");<Esc>?""<Enter>li', -- Basic print
  ["souti<Tab>"] = 'print(f"x: {x}");<Esc>Fxciw', -- Print int
  ["souts<Tab>"] = 'print(f"x: {x}");<Esc>Fxciw', -- Print string
  ["soutb<Tab>"] = 'print(f"x: {"true" if x else "false"}");<Esc>Fxciw', -- Print boolean
  ["soutf<Tab>"] = 'print(f"x: {x:.2f}");<Esc>Fxciw', -- Print float
  ["soutd<Tab>"] = 'print(f"x: {x:.6f}");<Esc>Fxciw', -- Print double
  ["soutc<Tab>"] = 'print(f"x: {chr(x)}");<Esc>Fxciw', -- Print character
  ["soutp<Tab>"] = 'print(f"x: {x}");<Esc>Fxciw', -- Print pointer (just show the value)
  ["for<Tab>"] = 'for i in range():<Esc>hi',
  ["fore<Tab>"] = 'for i in :<Esc>i'
})

-- Rust
create_mappings("rs,rust", {
  ["sout<Tab>"] = 'println!("");<Esc>?""<Enter>li', -- Basic print
  ["souti<Tab>"] = 'println!("x: {}", x);<Esc>Fxciw', -- Print int
  ["souts<Tab>"] = 'println!("x: {}", x);<Esc>Fxciw', -- Print string
  ["soutb<Tab>"] = 'println!("x: {}", if x { "true" } else { "false" });<Esc>Fxciw', -- Print boolean
  ["soutf<Tab>"] = 'println!("x: {:.2}", x);<Esc>Fxciw', -- Print float
  ["soutd<Tab>"] = 'println!("x: {:.6}", x);<Esc>Fxciw', -- Print double
  ["soutc<Tab>"] = 'println!("x: {}", x as char);<Esc>Fxciw', -- Print character
  ["soutp<Tab>"] = 'println!("x: {:?}", &x);<Esc>Fxciw', -- Print pointer address (just show the value)
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

local function update_wildignore(filetype)
    local wildignore = vim.opt.wildignore:get()

    if filetype == "rust" then
        if not vim.tbl_contains(wildignore, "*/target/*") then
            table.insert(wildignore, "*/target/*")
        end
    elseif filetype == "cs" then
        if not vim.tbl_contains(wildignore, "*/bin/*") then
            table.insert(wildignore, "*/bin/*")
        end
        if not vim.tbl_contains(wildignore, "*/obj/*") then
            table.insert(wildignore, "*/obj/*")
        end
    elseif filetype == "cpp" or filetype == "c" then
        if not vim.tbl_contains(wildignore, "*/build/*") then
            table.insert(wildignore, "*/build/*")
        end
    end

    vim.opt.wildignore = wildignore
end

vim.api.nvim_create_autocmd({"BufRead", "BufNewFile"}, {
    pattern = { "*.rs", "*.cs", "*.cpp", "*.c" },
    callback = function()
        local filetype = vim.bo.filetype
        update_wildignore(filetype)
    end,
})

-- use leader-, on line below
-- :lua print(vim.inspect(vim.opt.wildignore:get()))

