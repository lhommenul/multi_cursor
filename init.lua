local M = {}

M.cursor_positions = {}

-- ... (fonctions existantes : add_cursor, remove_cursor, move_cursors, update_highlights)
--
function M.add_cursor()
    local cur_pos = vim.api.nvim_win_get_cursor(0)
    table.insert(M.cursor_positions, cur_pos)
    vim.api.nvim_buf_add_highlight(0, -1, "MultiCursor", cur_pos[1] - 1, cur_pos[2], cur_pos[2] + 1)
end

-- Supprime le dernier curseur ajouté
function M.remove_cursor()
    if #M.cursor_positions > 0 then
        local pos = table.remove(M.cursor_positions)
        vim.api.nvim_buf_clear_namespace(0, -1, pos[1] - 1, pos[1])
    end
end

-- Met à jour les surlignages des curseurs
function M.update_highlights()
    vim.api.nvim_buf_clear_namespace(0, -1, 0, -1)
    for _, pos in ipairs(M.cursor_positions) do
        vim.api.nvim_buf_add_highlight(0, -1, "MultiCursor", pos[1] - 1, pos[2], pos[2] + 1)
    end
end

-- Déplace tous les curseurs
function M.move_cursors(direction)
    for i, pos in ipairs(M.cursor_positions) do
        if direction == "h" then
            pos[2] = math.max(0, pos[2] - 1)
        elseif direction == "l" then
            pos[2] = pos[2] + 1
        elseif direction == "j" then
            pos[1] = pos[1] + 1
        elseif direction == "k" then
            pos[1] = math.max(1, pos[1] - 1)
        end
        M.cursor_positions[i] = pos
    end
    M.update_highlights()
end
-- Nouvelle fonction pour effectuer une opération sur tous les curseurs
function M.apply_to_cursors(operation)
    local buf = vim.api.nvim_get_current_buf()
    local changes = {}
    
    for _, pos in ipairs(M.cursor_positions) do
        local line = vim.api.nvim_buf_get_lines(buf, pos[1] - 1, pos[1], false)[1]
        local new_line = operation(line, pos[2])
        if new_line ~= line then
            table.insert(changes, {
                start = pos[1] - 1,
                lines = {new_line}
            })
        end
    end
    
    -- Appliquer les changements en commençant par la fin pour éviter les décalages
    for i = #changes, 1, -1 do
        local change = changes[i]
        vim.api.nvim_buf_set_lines(buf, change.start, change.start + 1, false, change.lines)
    end
    
    M.update_highlights()
end

-- Exemples d'opérations

-- Insérer un caractère à chaque curseur
function M.insert_at_cursors()
    -- Demander à l'utilisateur d'entrer une phrase
    local phrase = vim.fn.input("Entrez la phrase à insérer : ")
    if phrase == "" then
        return  -- Ne rien faire si l'entrée est vide
    end

    M.apply_to_cursors(function(line, col)
        return line:sub(1, col) .. phrase .. line:sub(col + 1)
    end)
end

-- Supprimer un caractère à chaque curseur
function M.delete_at_cursors()
    M.apply_to_cursors(function(line, col)
        return line:sub(1, col - 1) .. line:sub(col + 1)
    end)
end

-- Configuration du plugin (mise à jour)
function M.setup()
    vim.api.nvim_command("highlight MultiCursor guifg=white guibg=steelblue")
    
    -- Mappages existants
    vim.api.nvim_set_keymap('n', '<Leader>a', ':lua require("multi_cursor").add_cursor()<CR>', {noremap = true, silent = true})
    vim.api.nvim_set_keymap('n', '<Leader>r', ':lua require("multi_cursor").remove_cursor()<CR>', {noremap = true, silent = true})
    vim.api.nvim_set_keymap('n', '<Leader>h', ':lua require("multi_cursor").move_cursors("h")<CR>', {noremap = true, silent = true})
    vim.api.nvim_set_keymap('n', '<Leader>j', ':lua require("multi_cursor").move_cursors("j")<CR>', {noremap = true, silent = true})
    vim.api.nvim_set_keymap('n', '<Leader>k', ':lua require("multi_cursor").move_cursors("k")<CR>', {noremap = true, silent = true})
    vim.api.nvim_set_keymap('n', '<Leader>l', ':lua require("multi_cursor").move_cursors("l")<CR>', {noremap = true, silent = true})
    
    -- Nouveaux mappages pour les opérations
    vim.api.nvim_set_keymap('n', '<Leader>i', ':lua require("multi_cursor").insert_at_cursors(vim.fn.nr2char(vim.fn.getchar()))<CR>', {noremap = true, silent = true})
    vim.api.nvim_set_keymap('n', '<Leader>x', ':lua require("multi_cursor").delete_at_cursors()<CR>', {noremap = true, silent = true})
end

return M
