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
create_mappings("vtxt,vimwiki,wiki,text,md,markdown", {
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
  ["sout<Tab>"] = 'printf("");<Esc>?""<Enter>li',
  ["souti<Tab>"] = 'printf("x: %d\\n", x);<Esc>Fxciw',
  ["souts<Tab>"] = 'printf("x: %s\\n", x);<Esc>Fxciw',
  ["soutb<Tab>"] = 'printf("x: %s\\n", x ? "true" : "false");<Esc>Fxciw',
  ["soutf<Tab>"] = 'printf("x: %.2f\\n", x);<Esc>Fxciw',
  ["soutd<Tab>"] = 'printf("x: %.6f\\n", x);<Esc>Fxciw',
  ["soutc<Tab>"] = 'printf("x: %c\\n", x);<Esc>Fxciw',
  ["soutp<Tab>"] = 'printf("x: %p\\n", (void*)&x);<Esc>Fxciw', -- Pointer address
  ["for<Tab>"] = 'for(int i = 0; i < val; i++){<Enter><Enter>}<Esc>?val<Enter>ciw',
  ["fore<Tab>"] = 'for (int i = 0; i < length; i++) {<Enter>printf("El: %d\\n", arr[i]);<Enter>}<Esc>?arr<Enter>ciw'
})

-- C++
create_mappings("cpp,c++", {
  ["sout<Tab>"] = 'std::cout << ""; std::endl;<Esc>?""<Enter>li',
  ["souti<Tab>"] = 'std::cout << "x: " << x << std::endl;<Esc>Fxciw',
  ["souts<Tab>"] = 'std::cout << "x: " << x << std::endl;<Esc>Fxciw',
  ["soutb<Tab>"] = 'std::cout << "x: " << (x ? "true" : "false") << std::endl;<Esc>Fxciw',
  ["soutf<Tab>"] = 'std::cout << "x: " << std::fixed << std::setprecision(2) << x << std::endl;<Esc>Fxciw',
  ["soutd<Tab>"] = 'std::cout << "x: " << std::fixed << std::setprecision(6) << x << std::endl;<Esc>Fxciw',
  ["soutc<Tab>"] = 'std::cout << "x: " << static_cast<char>(x) << std::endl;<Esc>Fxciw',
  ["soutp<Tab>"] = 'std::cout << "x: " << &x << std::endl;<Esc>Fxciw', -- Pointer address
  ["for<Tab>"] = 'for(int i = 0; i < val; i++){<Enter><Enter>}<Esc>?val<Enter>ciw',
  ["fore<Tab>"] = 'for (auto& el : arr) {<Enter><Enter>}<Esc>?arr<Enter>ciw'
})

-- C#
create_mappings("cs", {
  ["sout<Tab>"] = 'Console.WriteLine("");<Esc>?""<Enter>li',
  ["souti<Tab>"] = 'Console.WriteLine($"x: {x}");<Esc>Fxciw',
  ["souts<Tab>"] = 'Console.WriteLine($"x: {x}");<Esc>Fxciw',
  ["soutb<Tab>"] = 'Console.WriteLine($"x: {x}");<Esc>Fxciw',
  ["soutf<Tab>"] = 'Console.WriteLine($"x: {x:F2}");<Esc>Fxciw',
  ["soutd<Tab>"] = 'Console.WriteLine($"x: {x:F6}");<Esc>Fxciw',
  ["soutc<Tab>"] = 'Console.WriteLine($"x: {(char)x}");<Esc>Fxciw',
  ["soutp<Tab>"] = 'Console.WriteLine($"x: {x}");<Esc>Fxciw', -- Pointer value
  ["fore<Tab>"] = 'foreach (var x in obj)<Enter>{<Enter><Enter>}<Esc>?obj<Enter>ciw',
  ["for<Tab>"] = 'for(int i = 0; i < val; i++){<Enter><Enter>}<Esc>?val<Enter>ciw'
})

-- Go
create_mappings("go", {
  ["sout<Tab>"] = 'fmt.Println("");<Esc>2F"li',
  ["souti<Tab>"] = 'fmt.Printf("x: %d\\n", x)<Esc>Fxciw',
  ["souts<Tab>"] = 'fmt.Printf("x: %s\\n", x)<Esc>Fxciw',
  ["soutb<Tab>"] = 'fmt.Printf("x: %t\\n", x)<Esc>Fxciw',
  ["soutf<Tab>"] = 'fmt.Printf("x: %.2f\\n", x)<Esc>Fxciw',
  ["soutd<Tab>"] = 'fmt.Printf("x: %.6f\\n", x)<Esc>Fxciw',
  ["soutc<Tab>"] = 'fmt.Printf("x: %c\\n", x)<Esc>Fxciw',
  ["soutp<Tab>"] = 'fmt.Printf("x: %p\\n", &x)<Esc>Fxciw', -- Pointer address
  ["for<Tab>"] = 'for i := 0; i < val; i++ {<Enter><Enter>}<Esc>?val<Enter>ciw',
  ["fore<Tab>"] = 'for idx, el := range arr {<Enter><Enter>}<Esc>?arr<Enter>ciw'
})

-- Java
create_mappings("java", {
  ["sout<Tab>"] = 'System.out.println("");<Esc>?""<Enter>li',
  ["souti<Tab>"] = 'System.out.println("x: " + x);<Esc>Fxciw',
  ["souts<Tab>"] = 'System.out.println("x: " + x);<Esc>Fxciw',
  ["soutb<Tab>"] = 'System.out.println("x: " + (x ? "true" : "false"));<Esc>Fxciw',
  ["soutf<Tab>"] = 'System.out.printf("x: %.2f%n", x);<Esc>Fxciw',
  ["soutd<Tab>"] = 'System.out.printf("x: %.6f%n", x);<Esc>Fxciw',
  ["soutc<Tab>"] = 'System.out.println("x: " + (char)x);<Esc>Fxciw',
  ["soutp<Tab>"] = 'System.out.println("x: " + x);<Esc>Fxciw', -- Pointer value
  ["fore<Tab>"] = 'for (String s : obj){<Enter><Enter>}<Esc>?obj<Enter>ciw',
  ["for<Tab>"] = 'for(int i = 0; i < val; i++){<Enter><Enter>}<Esc>?val<Enter>ciw',
  ["psvm<Tab>"] = 'public static void main(String[] args){<Enter><Enter>}<Esc>?{<Enter>o'
})

-- Js/Ts
create_mappings("js,ts,javascript,typescript", {
  ["sout<Tab>"] = 'console.log("");<Esc>?""<Enter>li',
  ["souti<Tab>"] = 'console.log(`x: ${x}`);<Esc>Fxciw',
  ["souts<Tab>"] = 'console.log(`x: ${x}`);<Esc>Fxciw',
  ["soutb<Tab>"] = 'console.log(`x: ${x}` ? "true" : "false");<Esc>Fxciw',
  ["soutf<Tab>"] = 'console.log(`x: ${x.toFixed(2)}`);<Esc>Fxciw',
  ["soutd<Tab>"] = 'console.log(`x: ${x.toFixed(6)}`);<Esc>Fxciw',
  ["soutc<Tab>"] = 'console.log(`x: ${String.fromCharCode(x)}`);<Esc>Fxciw',
  ["soutp<Tab>"] = 'console.log(`x: ${x}`);<Esc>Fxciw', -- Pointer value
  ["for<Tab>"] = 'for (let i = 0; i < val; i++) {<Enter><Enter>}<Esc>?val<Enter>ciw',
  ["fore<Tab>"] = 'arr.forEach(el => {<Enter><Enter>});<Esc>?arr<Enter>ciw'
})

-- Lua
create_mappings("lua", {
  ["sout<Tab>"] = 'print("")<Esc>?""<Enter>li',
  ["souti<Tab>"] = 'print("x: " .. x)<Esc>Fxciw',
  ["souts<Tab>"] = 'print("x: " .. x)<Esc>Fxciw',
  ["soutb<Tab>"] = 'print("x: " .. (x and "true" or "false"))<Esc>Fxciw',
  ["soutf<Tab>"] = 'print(string.format("x: %.2f", x))<Esc>Fxciw',
  ["soutd<Tab>"] = 'print(string.format("x: %.6f", x))<Esc>Fxciw',
  ["soutc<Tab>"] = 'print("x: " .. string.char(x))<Esc>Fxciw',
  ["soutp<Tab>"] = 'print("x: " .. tostring(x))<Esc>Fxciw', -- Pointer value
  ["for<Tab>"] = 'for i = 1, val, 1 do<Enter><Enter>end<Esc>?val<Enter>ciw',
  ["fore<Tab>"] = 'for i, el in ipairs(arr) do<Enter><Enter>end<Esc>?arr<Enter>ciw'
})

-- Php
create_mappings("php", {
  ["sout<Tab>"] = 'echo "";<Esc>?""<Enter>li',
  ["souti<Tab>"] = 'echo "x: $x\\n";<Esc>Fxciw',
  ["souts<Tab>"] = 'echo "x: $x\\n";<Esc>Fxciw',
  ["soutb<Tab>"] = 'echo "x: " . ($x ? "true" : "false") . "\\n";<Esc>Fxciw',
  ["soutf<Tab>"] = 'echo "x: " . number_format($x, 2) . "\\n";<Esc>Fxciw',
  ["soutd<Tab>"] = 'echo "x: " . number_format($x, 6) . "\\n";<Esc>Fxciw',
  ["soutc<Tab>"] = 'echo "x: " . chr($x) . "\\n";<Esc>Fxciw',
  ["soutp<Tab>"] = 'echo "x: " . $x . "\\n";<Esc>Fxciw', -- Pointer value
  ["for<Tab>"] = 'for ($i = 0; $i < $val; $i++) {<Enter><Enter>}<Esc>?val<Enter>ciw',
  ["fore<Tab>"] = 'foreach ($arr as $el) {<Enter><Enter>}<Esc>?arr<Enter>ciw'
})

-- Python
create_mappings("py,python", {
  ["sout<Tab>"] = 'print("")<Esc>?""<Enter>li',
  ["souti<Tab>"] = 'print(f"x: {x}")<Esc>Fxciw',
  ["souts<Tab>"] = 'print(f"x: {x}")<Esc>Fxciw',
  ["soutb<Tab>"] = 'print(f"x: {"true" if x else "false"}")<Esc>Fxciw',
  ["soutf<Tab>"] = 'print(f"x: {x:.2f}")<Esc>Fxciw',
  ["soutd<Tab>"] = 'print(f"x: {x:.6f}")<Esc>Fxciw',
  ["soutc<Tab>"] = 'print(f"x: {chr(x)}")<Esc>Fxciw',
  ["soutp<Tab>"] = 'print(f"x: {x}")<Esc>Fxciw', -- Pointer value
  ["for<Tab>"] = 'for i in range():<Esc>hi',
  ["fore<Tab>"] = 'for i in :<Esc>i'
})

-- Rust
create_mappings("rs,rust", {
  ["sout<Tab>"] = 'println!("");<Esc>?""<Enter>li',
  ["souti<Tab>"] = 'println!("x: {}", x);<Esc>Fxciw',
  ["souts<Tab>"] = 'println!("x: {}", x);<Esc>Fxciw',
  ["soutb<Tab>"] = 'println!("x: {}", if x { "true" } else { "false" });<Esc>Fxciw',
  ["soutf<Tab>"] = 'println!("x: {:.2}", x);<Esc>Fxciw',
  ["soutd<Tab>"] = 'println!("x: {:.6}", x);<Esc>Fxciw',
  ["soutc<Tab>"] = 'println!("x: {}", x as char);<Esc>Fxciw',
  ["soutp<Tab>"] = 'println!("x: {:?}", &x);<Esc>Fxciw', -- Pointer address
  ["for<Tab>"] = 'for i in 0..val {<Enter><Enter>}<Esc>?val<Enter>ciw',
  ["fore<Tab>"] = 'for el in arr.iter() {<Enter><Enter>}<Esc>?arr<Enter>ciw'
})

-- Bash
create_mappings("sh,bash", {
  ["sout<Tab>"] = 'echo "";<Esc>?""<Enter>li',
  ["souti<Tab>"] = 'echo "x: $x";<Esc>0f$ciw',
  ["souts<Tab>"] = 'echo "x: $x";<Esc>0f$ciw',
  ["soutb<Tab>"] = 'if [ "$x" = "true" ]; then echo "x: true"; else echo "x: false"; fi;<Esc>0f$ciw',
  ["soutf<Tab>"] = 'printf "x: %.2f\\n" "$x";<Esc>0f$ciw',
  ["for<Tab>"] = 'for i in {1..10}; do<Enter>echo "Element: $i"<Enter>done<Esc>kA<Enter>',
  ["fore<Tab>"] = 'for item in "${array[@]}"; do<Enter>echo "Item: $item"<Enter>done<Esc>kA<Enter>'
})

-- PowerShell
create_mappings("ps1,powershell", {
  ["sout<Tab>"] = 'Write-Output ""<Esc>?""<Enter>li',
  ["souti<Tab>"] = 'Write-Output "x: $x"<Esc>0f$ciw',
  ["souts<Tab>"] = 'Write-Output "x: $x"<Esc>0f$ciw',
  ["soutb<Tab>"] = 'Write-Output ("x: " + ($x -eq $true ? "true" : "false"))<Esc>0f$ciw',
  ["soutf<Tab>"] = 'Write-Output ("x: " + "{0:N2}" -f $x)<Esc>0f$ciw',
  ["for<Tab>"] = 'for ($i = 0; $i -lt 10; $i++) {<Enter>Write-Output "Element: $i"<Enter>}<Esc>kA<Enter>',
  ["fore<Tab>"] = 'foreach ($item in $array) {<Enter>Write-Output "Item: $item"<Enter>}<Esc>kA<Enter>'
})

-- Helper function to read key-value pairs from config file
-- local function read_config_file(filepath)
--     local keys = {}
--     for line in io.lines(filepath) do
--         local key, value = line:match("([^:]+):%s*(.+)")
--         if key and value and #value > 60 then
--             table.insert(keys, key)
--         end
--     end
--     return keys
-- end
-- 
-- -- Function to insert the list of keys into the current buffer
-- function insert_long_value_keys()
--     local config_path = "C:\\local\\config.txt"
--     local keys = read_config_file(config_path)
--     if #keys > 0 then
--         local keys_string = table.concat(keys, ", ")
--         vim.api.nvim_put({ keys_string }, "l", true, true)
--         print("Inserted keys: " .. keys_string)
--     else
--         print("No keys with values longer than 60 characters found.")
--     end
-- end
-- 
-- -- Create autocommand for SQL files
-- vim.api.nvim_create_autocmd("FileType", {
--     pattern = "sql",
--     callback = function()
--         local bufnr = vim.api.nvim_get_current_buf()
--         vim.api.nvim_buf_set_keymap(bufnr, "i", "cnf<Tab>", "<cmd>lua insert_long_value_keys()<CR>", { noremap = true, silent = true })
--     end
-- })

-- Helper function to read the Program.cs file and extract engine and env values
local function read_program_cs()
    local code_root_dir = os.getenv("code_root_dir")
    if not code_root_dir then
        print("Environment variable 'code_root_dir' is not set.")
        return nil
    end

    local program_cs_path = code_root_dir .. "/Code2/Sql/my_sql/SqlExec/SqlExec/Program.cs"

    -- Check if the file exists
    local file = io.open(program_cs_path, "r")
    if not file then
        print("Program.cs file not found at: " .. program_cs_path)
        return nil
    end

    -- Extract engine and env values
    local engines = {}
    table.insert(engines, "sql_server")
    engines["sql_server"] = true
    local envs = {}
    for line in file:lines() do
        -- Match engine values
        local engine = line:match('engine:%s*(%w+)')
        if engine and not engines[engine] then
            table.insert(engines, engine:lower())
            engines[engine] = true
        end

        -- Match env values
        local env = line:match('env:%s*(%w+)')
        if env and not envs[env] then
            table.insert(envs, env:lower())
            envs[env] = true
        end
    end

    file:close()

    -- Return comma-separated lists
    return table.concat(engines, ", "), table.concat(envs, ", ")
end

-- Function to insert the engine and env values into the current buffer
--function insert_engine_env_values()
--    local engines, envs = read_program_cs()
--    if not engines or not envs then
--        return
--    end
--
--    -- Insert values into the buffer
--    local engine_line = "--engine: " .. engines
--    local env_line = "--env: " .. envs
--    local blank_line = ""
--
--    vim.api.nvim_put({ engine_line, env_line, blank_line }, "l", true, true)
--end
-- No initial new line
function insert_engine_env_values()
    local engines, envs = read_program_cs()
    if not engines or not envs then
        return
    end

    -- Prepare lines to insert
    local engine_line = "--engine: " .. engines
    local env_line = "--env: " .. envs
    local blank_line = ""

    -- Move the cursor to the end of the current line
    local row, col = unpack(vim.api.nvim_win_get_cursor(0))
    vim.api.nvim_win_set_cursor(0, { row, col + 1 })

    -- Insert lines into the buffer without an extra newline at the start
    vim.api.nvim_put({ engine_line, env_line, blank_line }, "c", true, true)
end

-- Autocommand for SQL files
vim.api.nvim_create_autocmd("FileType", {
    pattern = "sql",
    callback = function()
        local bufnr = vim.api.nvim_get_current_buf()
        vim.api.nvim_buf_set_keymap(bufnr, "i", "cnf<Tab>", "<cmd>lua insert_engine_env_values()<CR>", { noremap = true, silent = true })
    end
})

local function run_pdflatex()
    local file = vim.fn.expand('%:p')
    vim.fn.jobstart({'pdflatex', file})
end

-- Autocommand to run pdflatex on write for .tex files
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

