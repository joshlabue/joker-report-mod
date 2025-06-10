local joker_report_save_directory = "joker_report"

local jr_version = "0.0.0"
local game_in_progress = false
local round_in_progress = false
local most_recent_hand = "" 
local jokers = {}

local current_run_id = nil
function jr_generate_game_id()
    local random = math.random
    math.randomseed(os.time())
    local template ='xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'
    return string.gsub(template, '[xy]', function (c)
        local v = (c == 'x') and random(0, 0xf) or random(8, 0xb)
        return string.format('%x', v)
    end)
end

local file_handle
function jr_log_action(action)

    if current_run_id == nil then
        print("Failed to log action: no run id")
        return
    end

    print("Joker Report action logged: " .. action)

   if not file_handle then
       if not love.filesystem.exists(joker_report_save_directory) then
           local result = love.filesystem.createDirectory(joker_report_save_directory)
           if not result then
               print("Failed to create directory: " .. joker_report_save_directory)
               return
           end
       end

       local file_name = joker_report_save_directory .. "/" .. current_run_id .. ".jokerreport"
       if not love.filesystem.exists(file_name) then
           file_handle = love.filesystem.newFile(file_name)
           file_handle:open("w")
       else
           file_handle = love.filesystem.newFile(file_name)
           file_handle:open("a")
       end

       print("Joker Report file opened: " .. file_name)
   end 

   file_handle:write(action .. "\n")
end

local hooked_generate_starting_seed = generate_starting_seed
function generate_starting_seed()
    local base_call = hooked_generate_starting_seed()
    -- randomly generated seed
    jr_set_seed(base_call)

    return base_call
end

function jr_serialize_playing_card(card)
    local card_value = card.base.value
    local card_suit = card.base.suit
    local ability = card.ability.effect
    local edition = "." 
    local seal = "."

    if card.edition then
        if card.edition.foil then
            edition = "Foil"
        elseif card.edition.holo then
            edition = "Holo"
        elseif card.edition.polychrome then
            edition = "Polychrome"
        elseif card.edition.negative then
            edition = "Negative"
        end 
    end

    local value_char = card_value
    if card_value == "Jack" then
        value_char = "J"
    elseif card_value == "Queen" then
        value_char = "Q"
    elseif card_value == "King" then
        value_char = "K"
    elseif card_value == "Ace" then
        value_char = "A"
    elseif card_value == "10" then
        value_char = "X"
    end

    local suit_char = "."
    if card_suit == "Hearts" then
        suit_char = "H"
    elseif card_suit == "Diamonds" then
        suit_char = "D"
    elseif card_suit == "Clubs" then
        suit_char = "C"
    elseif card_suit == "Spades" then
        suit_char = "S"
    end

    local ability_char = "."
    if ability == "Stone Card" then
        ability_char = "S"
    elseif ability == "Bonus Card" then
        ability_char = "B"
    elseif ability == "Mult Card" then
        ability_char = "M"
    elseif ability == "Wild Card" then
        ability_char = "W"
    elseif ability == "Glass Card" then
        ability_char = "G"
    elseif ability == "Steel Card" then
        ability_char = "T"
    elseif ability == "Gold Card" then
        ability_char = "O"
    elseif ability == "Lucky Card" then
        ability_char = "L"
    end

    local edition_char = "."
    if edition == "Foil" then
        edition_char = "#"
    elseif edition == "Holo" then
        edition_char = "+"
    elseif edition == "Polychrome" then
        edition_char = "*"
    elseif edition == "Negative" then
        edition_char = "-"
    end

    local seal = "."
    if card.seal then
        if card.seal == "Gold" then
            seal = "G"
        elseif card.seal == "Red" then
            seal = "R"
        elseif card.seal == "Blue" then
            seal = "B"
        elseif card.seal == "Purple" then
            seal = "P"
        end
    end

    return value_char .. suit_char .. ability_char .. edition_char .. seal
end


local hooked_eval_play = G.FUNCS.evaluate_play
function G.FUNCS:evaluate_play(e)
    local cards = G.play.cards

    local joker_order = "JOKERORDER"
    for i=1, #G.jokers.cards do
        joker_order = joker_order .. " " .. G.jokers.cards[i].ID
    end
    jr_log_action(joker_order)

    for i=1, #G.play.cards do

        local card = G.play.cards[i]
       
        local edition_string = ""
        if edition then
           edition_string = " " .. edition 
        end
            
        jr_log_action ("CARD " .. jr_serialize_playing_card(card) .. " " .. card.ID)
    end 

    local base_call = hooked_eval_play(e)
    local hand_score = hand_chips * mult
    local hand_level = 1
    if G.GAME.hands[most_recent_hand] ~= nil then
        hand_level = G.GAME.hands[most_recent_hand].level
    end
    jr_log_action("SCORE " .. hand_score .. " " .. most_recent_hand .. " " .. hand_level)
end

local hooked_highlight_card = highlight_card
function highlight_card(card, percent, dir)
    local base_call = hooked_highlight_card(card, percent, dir)

    if(dir == 'up') then
        jr_log_action("CARDSCORED " .. jr_serialize_playing_card(card) .. " " .. card.ID)
    end

    return base_call
end

local hooked_use_consumable = Card.use_consumeable
function Card:use_consumeable(area, copier)

    local cards_before = {}

    for i=1, #G.playing_cards do
        local card = G.playing_cards[i]
    
        cards_before[i] = { }
        cards_before[i].value = jr_serialize_playing_card(card)
        cards_before[i].matched = false
        cards_before[i].id = card.ID
    end

    local base_call = hooked_use_consumable(self, area, copier)

    G.E_MANAGER:add_event(Event({
        func = function() 
            if (G.GAME.STOP_USE and G.GAME.STOP_USE > 0) then
                return false
            end
            
            local cards_after = {}
            for i=1, #G.playing_cards do
                local card = G.playing_cards[i]
                local serialied_card = jr_serialize_playing_card(card)
                
                cards_after[i] = { }
                cards_after[i].value = serialied_card
                cards_after[i].matched = false
                cards_after[i].id = card.ID
            end

            for i=1, #cards_before do
                local before = cards_before[i]
                for j=1, #cards_after do
                    local after = cards_after[j]
                    if before.value == after.value and not before.matched and not after.matched then
                        before.matched = true
                        after.matched = true
                        break
                    end
                end
            end

            for i=1, #cards_before do
                local before = cards_before[i]
                if not before.matched then
                    jr_log_action("-CARD " .. before.value .. " " .. before.id)
                end
            end

            for i=1, #cards_after do
                local after = cards_after[i]
                if not after.matched then
                    jr_log_action("+CARD " .. after.value .. " " .. after.id)
                end
            end

            jr_log_action("CONSUME END")            
            
            return true
        end,
        blocking = false
    }))

    jr_log_action("CONSUME START " .. self.ability.name)
end

local hooked_start_setup_run = G.FUNCS.start_setup_run
function G.FUNCS:start_setup_run(e)
    local base_call = hooked_start_setup_run(self, e)

    if G.SETTINGS.current_setup == 'Continue' then
        print("CONTINUE")
        print("ID orphan")
    elseif G.SETTINGS.current_setup == 'New Run' then
        current_run_id = jr_generate_game_id() 
        file_handle = nil
        jr_log_action("ID " .. current_run_id) 
        jr_log_action("VERSION " .. VERSION .. " " .. jr_version)
        -- jr_log_action("NEW " .. G.GAME.selected_back.name)
    end

    local _seed = G.run_setup_seed and G.setup_seed or G.forced_seed or nil
    if _seed then
        -- user specified seed
        jr_set_seed(_seed, true)
    end
end

local hooked_apply_to_run = Back.apply_to_run
function Back:apply_to_run()
    local base_call = hooked_apply_to_run(self)

    jr_log_action("NEW " .. self.name)
end


local hooked_start_run = Game.start_run
function Game:start_run(args)
    local base_call = hooked_start_run(self, args)
    round_in_progress = false;

    jr_log_action("STAKE " .. G.GAME.stake)
end

local hooked_skip_blind = G.FUNCS.skip_blind
function G.FUNCS:skip_blind(e)
    local skipped_blind = G.GAME.blind_on_deck
    local base_call = hooked_skip_blind(self, e)
    if G.GAME.blind then
        jr_log_action("ANTE " .. G.GAME.round_resets.ante)
        jr_log_action("SKIP " .. skipped_blind)
    end
end

local hooked_add_tag = add_tag
function add_tag(_tag)
    local base_call = hooked_add_tag(_tag)
    jr_log_action("TAG " .. G.P_TAGS[_tag.key].name)
end

local hooked_select_blind = Blind.set_blind
function Blind:set_blind(blind, reset, silent)
    local base_call = hooked_select_blind(self, blind, reset, silent)

    game_in_progress = true 

    if round_in_progress then
        return
    end

    if G.GAME.blind and not silent then 
        jr_log_action("ANTE " .. G.GAME.round_resets.ante)
        round_in_progress = true
        local blind = G.GAME.blind_on_deck
        if G.GAME.blind_on_deck == "Boss" then
            jr_log_action("BLIND " .. G.GAME.blind.name)
        else
            jr_log_action("BLIND " .. G.GAME.blind_on_deck) 
        end
        jr_log_action("NEED " .. G.GAME.blind.chips)
    end
end


local hooked_evaluate_round = G.FUNCS.evaluate_round
function G.FUNCS:evaluate_round()
    local base_call = hooked_evaluate_round(self)
    round_in_progress = false
end

local hooked_update_game_over = Game.update_game_over
function Game:update_game_over(dt)
    local base_call = hooked_update_game_over(self, dt)

    if game_in_progress and G.STATE_COMPLETE then
        jr_log_action("GAMEOVER")
        game_in_progress = false

        if file_handle then
            file_handle:close()
            file_handle = nil
        end
    end
end

local hooked_update_hand_text = update_hand_text
function update_hand_text(config, vals)
    local base_call = hooked_update_hand_text(config, vals)
    if vals.handname then
        if vals.handname ~= "" then
            most_recent_hand = vals.handname
        end
    end
end

local hooked_card_area_emplace = CardArea.emplace
function CardArea:emplace(card, location, stay_flipped)
    local base_call = hooked_card_area_emplace(self, card, location, stay_flipped)
    if G.jokers == self then
        jr_log_action("+JOKER " .. card.ability.name .. " " .. card.ID)
    end
end

local hooked_card_area_remove = CardArea.remove_card
function CardArea:remove_card(card, discarded_only)
    local base_call = hooked_card_area_remove(self, card, discarded_only)
    if G.jokers == self then
        jr_log_action("-JOKER " .. card.ability.name .. " " .. card.ID)
    end

    return base_call
end


function jr_set_seed(seed, forced)
    if forced then
        jr_log_action("SEED " .. seed .. " FORCED")
    else
        jr_log_action("SEED " .. seed)
    end
end

