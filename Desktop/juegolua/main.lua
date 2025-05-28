-- Game state constants
local GAME_STATE = {
    MENU = "menu",
    BATTLE = "battle",
    SHOP = "shop",
    BOSS_BATTLE = "boss_battle",
    GAME_OVER = "game_over"
}

-- Animation system
local animations = {
    cardPlay = {timer = 0, duration = 0.3},
    damage = {timer = 0, duration = 0.5},
    heal = {timer = 0, duration = 0.5},
    bossIntro = {timer = 0, duration = 2},
    cardEffect = {timer = 0, duration = 0.5},
    screenFlash = {timer = 0, duration = 0.2},
    cardDraw = {timer = 0, duration = 0.5},
    levelUp = {timer = 0, duration = 1},
    goldGain = {timer = 0, duration = 1}
}

-- Game assets
local assets = {
    fonts = {},
    images = {},
    sounds = {},
    colors = {
        background = {0.1, 0.1, 0.15},
        cardBackground = {0.15, 0.15, 0.2},
        text = {1, 1, 1},
        energy = {1, 0.8, 0},
        health = {0.8, 0.2, 0.2},
        defense = {0.2, 0.6, 0.8},
        attack = {0.8, 0.2, 0.2},
        gold = {1, 0.8, 0},
        rare = {1, 0.8, 0},
        uncommon = {0.5, 0.5, 1},
        common = {0.8, 0.8, 0.8}
    }
}

-- Game variables
local currentState = GAME_STATE.MENU
local player = {
    health = 100,
    maxHealth = 100,
    deck = {},
    hand = {},
    attackBoost = 0,
    defenseBoost = 0,
    x = 200,
    y = 300,
    energy = 3,
    maxEnergy = 3,
    gold = 100,
    level = 1
}
local currentEnemy = nil
local currentLevel = 1
local playerTurn = true
local shopCards = {}
local screenShake = {x = 0, y = 0, timer = 0}
local selectedCard = nil
local cardEffects = {}
local gameOverMessage = ""
local buttonHover = nil
local floatingText = {}
local particleEffects = {}

-- Card definitions
local CARD_TYPES = {
    ATTACK = {
        name = "Attack",
        damage = 10,
        cost = 1,
        color = {1, 0, 0},
        description = "Deal 10 damage",
        rarity = "common"
    },
    HEAL = {
        name = "Heal",
        healing = 15,
        cost = 2,
        color = {0, 1, 0},
        description = "Heal 15 HP",
        rarity = "common"
    },
    DEFEND = {
        name = "Defend",
        block = 5,
        cost = 1,
        color = {0, 0, 1},
        description = "Gain 5 defense",
        rarity = "common"
    },
    BOOST_ATTACK = {
        name = "Boost Attack",
        attackBoost = 5,
        cost = 2,
        color = {1, 0.5, 0},
        description = "Gain 5 attack power",
        rarity = "uncommon"
    },
    BOOST_DEFENSE = {
        name = "Boost Defense",
        defenseBoost = 5,
        cost = 2,
        color = {0, 0.5, 1},
        description = "Gain 5 defense power",
        rarity = "uncommon"
    },
    HEAVY_ATTACK = {
        name = "Heavy Attack",
        damage = 25,
        cost = 3,
        color = {0.8, 0, 0},
        description = "Deal 25 damage",
        rarity = "rare"
    },
    MASS_HEAL = {
        name = "Mass Heal",
        healing = 30,
        cost = 3,
        color = {0, 0.8, 0},
        description = "Heal 30 HP",
        rarity = "rare"
    },
    DOUBLE_STRIKE = {
        name = "Double Strike",
        damage = 8,
        cost = 2,
        color = {1, 0.3, 0.3},
        description = "Deal 8 damage twice",
        rarity = "uncommon",
        hits = 2
    },
    VAMPIRE_STRIKE = {
        name = "Vampire Strike",
        damage = 12,
        healing = 6,
        cost = 2,
        color = {0.8, 0, 0.8},
        description = "Deal 12 damage and heal 6 HP",
        rarity = "rare"
    }
}

-- Load game assets
function love.load()
    -- Initialize game
    love.graphics.setDefaultFilter("nearest", "nearest")
    
    -- Load fonts
    assets.fonts.title = love.graphics.newFont(32)
    assets.fonts.normal = love.graphics.newFont(16)
    assets.fonts.small = love.graphics.newFont(12)
    
    -- Initialize player deck with initial cards
    player.deck = {
        CARD_TYPES.ATTACK,
        CARD_TYPES.ATTACK,
        CARD_TYPES.DEFEND,
        CARD_TYPES.DEFEND
    }
    
    -- Create card images
    createCardImages()
    
    -- Draw initial hand
    drawHand()
    
    -- Set initial game state
    currentState = GAME_STATE.MENU
    playerTurn = true
end

-- Update game state
function love.update(dt)
    -- Update animations
    for _, anim in pairs(animations) do
        if anim.timer > 0 then
            anim.timer = anim.timer - dt
        end
    end
    
    -- Update screen shake
    if screenShake.timer > 0 then
        screenShake.timer = screenShake.timer - dt
        screenShake.x = love.math.random(-5, 5)
        screenShake.y = love.math.random(-5, 5)
    else
        screenShake.x = 0
        screenShake.y = 0
    end

    if currentState == GAME_STATE.BATTLE or currentState == GAME_STATE.BOSS_BATTLE then
        updateBattle(dt)
    elseif currentState == GAME_STATE.SHOP then
        updateShop(dt)
    end
end

-- Draw game
function love.draw()
    -- Apply screen shake
    love.graphics.translate(screenShake.x, screenShake.y)
    
    if currentState == GAME_STATE.MENU then
        drawMenu()
    elseif currentState == GAME_STATE.BATTLE or currentState == GAME_STATE.BOSS_BATTLE then
        drawBattle()
    elseif currentState == GAME_STATE.SHOP then
        drawShop()
    elseif currentState == GAME_STATE.GAME_OVER then
        drawGameOver()
    end
end

-- Handle mouse clicks
function love.mousepressed(x, y, button)
    if button == 1 then -- Left click
        if currentState == GAME_STATE.MENU then
            if buttonHover == "start" then
                currentState = GAME_STATE.BATTLE
                startNewBattle()
            end
        elseif currentState == GAME_STATE.BATTLE or currentState == GAME_STATE.BOSS_BATTLE then
            if buttonHover == "end_turn" then
                playerTurn = false
                love.timer.after(1, enemyTurn)
            else
                handleBattleClick(x, y)
            end
        elseif currentState == GAME_STATE.SHOP then
            if buttonHover == "continue" then
                currentState = GAME_STATE.BATTLE
                startNewBattle()
            else
                handleShopClick(x, y)
            end
        elseif currentState == GAME_STATE.GAME_OVER then
            if buttonHover == "restart" then
                resetGame()
            end
        end
    end
end

-- Create card images
function createCardImages()
    -- Initialize images table if not exists
    assets.images = assets.images or {}
    
    -- Create card background images
    for cardType, card in pairs(CARD_TYPES) do
        local img = love.graphics.newCanvas(100, 150)
        love.graphics.setCanvas(img)
        
        -- Draw card background
        love.graphics.setColor(assets.colors.cardBackground)
        love.graphics.rectangle("fill", 0, 0, 100, 150)
        
        -- Draw card border
        love.graphics.setColor(card.color)
        love.graphics.rectangle("line", 2, 2, 96, 146)
        
        -- Draw card name
        love.graphics.setColor(1, 1, 1)
        love.graphics.setFont(assets.fonts.small)
        love.graphics.printf(card.name, 5, 5, 90, "center")
        
        -- Draw card cost
        love.graphics.setColor(assets.colors.energy)
        love.graphics.circle("fill", 20, 25, 10)
        love.graphics.setColor(0, 0, 0)
        love.graphics.printf(card.cost, 10, 20, 20, "center")
        
        -- Draw card effects
        love.graphics.setColor(1, 1, 1)
        if card.damage then
            love.graphics.print("⚔ " .. card.damage, 5, 45)
        end
        if card.healing then
            love.graphics.print("❤ " .. card.healing, 5, 45)
        end
        if card.block then
            love.graphics.print("🛡 " .. card.block, 5, 65)
        end
        if card.attackBoost then
            love.graphics.print("⚔+" .. card.attackBoost, 5, 85)
        end
        if card.defenseBoost then
            love.graphics.print("🛡+" .. card.defenseBoost, 5, 105)
        end
        if card.hits then
            love.graphics.print("↻ " .. card.hits, 5, 125)
        end
        
        -- Draw rarity indicator
        if card.rarity == "rare" then
            love.graphics.setColor(assets.colors.rare)
        elseif card.rarity == "uncommon" then
            love.graphics.setColor(assets.colors.uncommon)
        else
            love.graphics.setColor(assets.colors.common)
        end
        love.graphics.rectangle("fill", 5, 130, 90, 15)
        
        love.graphics.setCanvas()
        assets.images[cardType] = img
    end
end

-- Draw the player's hand
function drawHand()
    -- Clear current hand
    player.hand = {}
    
    -- Draw 5 cards
    for i = 1, 5 do
        if #player.deck > 0 then
            local randomIndex = love.math.random(1, #player.deck)
            table.insert(player.hand, player.deck[randomIndex])
            table.remove(player.deck, randomIndex)
        end
    end
    
    -- Debug print
    print("Hand size: " .. #player.hand)
end

-- Draw menu screen
function drawMenu()
    -- Draw background
    love.graphics.setColor(assets.colors.background)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    
    -- Draw title with glow effect
    love.graphics.setColor(1, 1, 1, 0.5)
    love.graphics.setFont(assets.fonts.title)
    love.graphics.printf("Roguelike Card Game", 0, 198, love.graphics.getWidth(), "center")
    love.graphics.printf("Roguelike Card Game", 0, 202, love.graphics.getWidth(), "center")
    love.graphics.printf("Roguelike Card Game", 2, 200, love.graphics.getWidth(), "center")
    love.graphics.printf("Roguelike Card Game", -2, 200, love.graphics.getWidth(), "center")
    
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("Roguelike Card Game", 0, 200, love.graphics.getWidth(), "center")
    
    -- Draw start button with hover effect
    local buttonX = love.graphics.getWidth() / 2 - 100
    local buttonY = 300
    local mouseX, mouseY = love.mouse.getPosition()
    
    if mouseX >= buttonX and mouseX <= buttonX + 200 and mouseY >= buttonY and mouseY <= buttonY + 50 then
        love.graphics.setColor(0.8, 0.8, 0.8)
        buttonHover = "start"
    else
        love.graphics.setColor(0.5, 0.5, 0.5)
        buttonHover = nil
    end
    
    -- Draw button shadow
    love.graphics.setColor(0, 0, 0, 0.3)
    love.graphics.rectangle("fill", buttonX + 4, buttonY + 4, 200, 50)
    
    -- Draw button
    love.graphics.setColor(buttonHover == "start" and {0.8, 0.8, 0.8} or {0.5, 0.5, 0.5})
    love.graphics.rectangle("fill", buttonX, buttonY, 200, 50)
    
    -- Draw button text
    love.graphics.setColor(0, 0, 0)
    love.graphics.setFont(assets.fonts.normal)
    love.graphics.printf("Start Game", buttonX, buttonY + 15, 200, "center")
end

-- Draw battle screen
function drawBattle()
    -- Draw background
    love.graphics.setColor(assets.colors.background)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    
    -- Draw player
    love.graphics.setColor(1, 1, 1)
    love.graphics.circle("fill", player.x, player.y, 30)
    
    -- Draw player stats box with shadow
    love.graphics.setColor(0, 0, 0, 0.3)
    love.graphics.rectangle("fill", 32, 32, 200, 150)
    love.graphics.setColor(0.2, 0.2, 0.2, 0.8)
    love.graphics.rectangle("fill", 30, 30, 200, 150)
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("line", 30, 30, 200, 150)
    
    -- Draw player stats with icons
    love.graphics.setFont(assets.fonts.normal)
    love.graphics.setColor(assets.colors.health)
    love.graphics.print("❤ " .. player.health, 50, 50)
    love.graphics.setColor(assets.colors.attack)
    love.graphics.print("⚔ " .. player.attackBoost, 50, 70)
    love.graphics.setColor(assets.colors.defense)
    love.graphics.print("🛡 " .. player.defenseBoost, 50, 90)
    love.graphics.setColor(assets.colors.energy)
    love.graphics.print("⚡ " .. player.energy .. "/" .. player.maxEnergy, 50, 110)
    love.graphics.setColor(assets.colors.gold)
    love.graphics.print("💰 " .. player.gold, 50, 130)
    
    -- Draw enemy if exists
    if currentEnemy then
        -- Draw enemy stats box with shadow
        love.graphics.setColor(0, 0, 0, 0.3)
        love.graphics.rectangle("fill", 32, 192, 200, 150)
        love.graphics.setColor(0.2, 0.2, 0.2, 0.8)
        love.graphics.rectangle("fill", 30, 190, 200, 150)
        love.graphics.setColor(1, 1, 1)
        love.graphics.rectangle("line", 30, 190, 200, 150)
        
        -- Draw enemy
        love.graphics.setColor(1, 0.5, 0.5)
        if currentEnemy.isBoss then
            -- Draw boss with glow effect
            love.graphics.setColor(1, 0, 0, 0.3)
            love.graphics.circle("fill", 800, 300, 55)
            love.graphics.setColor(1, 0.5, 0.5)
            love.graphics.circle("fill", 800, 300, 50)
            
            -- Boss intro animation
            if animations.bossIntro.timer > 0 then
                local scale = 1 + (animations.bossIntro.timer / animations.bossIntro.duration)
                love.graphics.setColor(1, 0, 0, animations.bossIntro.timer / animations.bossIntro.duration)
                love.graphics.circle("fill", 800, 300, 50 * scale)
            end
        else
            love.graphics.circle("fill", 800, 300, 30)
        end
        
        -- Draw enemy stats with icons
        love.graphics.setColor(assets.colors.health)
        local enemyTitle = currentEnemy.isBoss and "BOSS" or "Enemy"
        love.graphics.print("❤ " .. enemyTitle .. " Health: " .. currentEnemy.health, 50, 210)
        love.graphics.setColor(assets.colors.attack)
        love.graphics.print("⚔ " .. enemyTitle .. " Attack: " .. currentEnemy.attackBoost, 50, 230)
        love.graphics.setColor(assets.colors.defense)
        love.graphics.print("🛡 " .. enemyTitle .. " Defense: " .. currentEnemy.defenseBoost, 50, 250)
        
        -- Draw level indicator
        love.graphics.setColor(1, 1, 1)
        love.graphics.print("Level: " .. currentLevel, 50, 290)
    end
    
    -- Draw turn indicator with animation
    local turnY = 50 + math.sin(love.timer.getTime() * 5) * 5
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf(playerTurn and "Your Turn" or "Enemy Turn", 0, turnY, love.graphics.getWidth(), "center")
    
    -- Draw cards in hand
    if playerTurn then
        local screenWidth = love.graphics.getWidth()
        local cardWidth = 100
        local cardSpacing = 20
        local totalCards = #player.hand
        local totalWidth = (totalCards * cardWidth) + ((totalCards - 1) * cardSpacing)
        local startX = (screenWidth - totalWidth) / 2
        
        for i, card in ipairs(player.hand) do
            local cardX = startX + ((i-1) * (cardWidth + cardSpacing))
            local cardY = 500
            
            -- Draw card shadow
            love.graphics.setColor(0, 0, 0, 0.3)
            love.graphics.rectangle("fill", cardX + 4, cardY + 4, cardWidth, 150)
            
            -- Draw card background
            love.graphics.setColor(assets.colors.cardBackground)
            love.graphics.rectangle("fill", cardX, cardY, cardWidth, 150)
            
            -- Draw card border
            if player.energy >= card.cost then
                love.graphics.setColor(card.color)
            else
                love.graphics.setColor(0.5, 0.5, 0.5)
            end
            love.graphics.rectangle("line", cardX + 2, cardY + 2, cardWidth - 4, 146)
            
            -- Draw card name
            love.graphics.setColor(1, 1, 1)
            love.graphics.setFont(assets.fonts.small)
            love.graphics.printf(card.name, cardX + 5, cardY + 5, cardWidth - 10, "center")
            
            -- Draw card cost
            love.graphics.setColor(assets.colors.energy)
            love.graphics.circle("fill", cardX + 20, cardY + 25, 10)
            love.graphics.setColor(0, 0, 0)
            love.graphics.printf(card.cost, cardX + 10, cardY + 20, 20, "center")
            
            -- Draw card effects with icons
            love.graphics.setColor(1, 1, 1)
            if card.damage then
                love.graphics.print("⚔ " .. card.damage, cardX + 5, cardY + 45)
            end
            if card.healing then
                love.graphics.print("❤ " .. card.healing, cardX + 5, cardY + 45)
            end
            if card.block then
                love.graphics.print("🛡 " .. card.block, cardX + 5, cardY + 65)
            end
            if card.attackBoost then
                love.graphics.print("⚔+" .. card.attackBoost, cardX + 5, cardY + 85)
            end
            if card.defenseBoost then
                love.graphics.print("🛡+" .. card.defenseBoost, cardX + 5, cardY + 105)
            end
            if card.hits then
                love.graphics.print("↻ " .. card.hits, cardX + 5, cardY + 125)
            end
            
            -- Draw rarity indicator
            if card.rarity == "rare" then
                love.graphics.setColor(assets.colors.rare)
            elseif card.rarity == "uncommon" then
                love.graphics.setColor(assets.colors.uncommon)
            else
                love.graphics.setColor(assets.colors.common)
            end
            love.graphics.rectangle("fill", cardX + 5, cardY + 130, cardWidth - 10, 15)
            
            -- Draw card hover effect
            local mouseX, mouseY = love.mouse.getPosition()
            if mouseX >= cardX and mouseX <= cardX + cardWidth and mouseY >= cardY and mouseY <= cardY + 150 then
                if player.energy >= card.cost then
                    love.graphics.setColor(1, 1, 1, 0.2)
                    love.graphics.rectangle("fill", cardX, cardY, cardWidth, 150)
                    -- Draw card description
                    love.graphics.setColor(1, 1, 1)
                    love.graphics.setFont(assets.fonts.small)
                    love.graphics.printf(card.description, cardX, cardY - 30, cardWidth, "center")
                else
                    love.graphics.setColor(1, 0, 0, 0.2)
                    love.graphics.rectangle("fill", cardX, cardY, cardWidth, 150)
                    love.graphics.setColor(1, 0, 0)
                    love.graphics.setFont(assets.fonts.small)
                    love.graphics.printf("Not enough energy!", cardX, cardY - 30, cardWidth, "center")
                end
            end
        end
    end
    
    -- Draw end turn button with shadow
    local buttonX = love.graphics.getWidth() - 150
    local buttonY = 50
    local mouseX, mouseY = love.mouse.getPosition()
    
    if mouseX >= buttonX and mouseX <= buttonX + 100 and mouseY >= buttonY and mouseY <= buttonY + 30 then
        love.graphics.setColor(0.8, 0.8, 0.8)
        buttonHover = "end_turn"
    else
        love.graphics.setColor(0.5, 0.5, 0.5)
        buttonHover = nil
    end
    
    -- Draw button shadow
    love.graphics.setColor(0, 0, 0, 0.3)
    love.graphics.rectangle("fill", buttonX + 2, buttonY + 2, 100, 30)
    
    -- Draw button
    love.graphics.setColor(buttonHover == "end_turn" and {0.8, 0.8, 0.8} or {0.5, 0.5, 0.5})
    love.graphics.rectangle("fill", buttonX, buttonY, 100, 30)
    
    -- Draw button text
    love.graphics.setColor(0, 0, 0)
    love.graphics.setFont(assets.fonts.normal)
    love.graphics.printf("End Turn", buttonX, buttonY + 5, 100, "center")
    
    -- Draw floating text
    for i = #floatingText, 1, -1 do
        local text = floatingText[i]
        love.graphics.setColor(text.color[1], text.color[2], text.color[3], text.timer / text.duration)
        love.graphics.setFont(assets.fonts.normal)
        love.graphics.printf(text.text, text.x - 50, text.y, 100, "center")
        text.y = text.y - 50 * love.timer.getDelta()
        text.timer = text.timer - love.timer.getDelta()
        if text.timer <= 0 then
            table.remove(floatingText, i)
        end
    end
    
    -- Draw particle effects
    for i = #particleEffects, 1, -1 do
        local particle = particleEffects[i]
        love.graphics.setColor(particle.color[1], particle.color[2], particle.color[3], particle.timer / particle.duration)
        love.graphics.circle("fill", particle.x, particle.y, 2)
        particle.x = particle.x + particle.vx * love.timer.getDelta()
        particle.y = particle.y + particle.vy * love.timer.getDelta()
        particle.timer = particle.timer - love.timer.getDelta()
        if particle.timer <= 0 then
            table.remove(particleEffects, i)
        end
    end
    
    -- Draw screen flash
    if animations.screenFlash.timer > 0 then
        love.graphics.setColor(1, 1, 1, animations.screenFlash.timer / animations.screenFlash.duration)
        love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    end
end

-- Draw shop screen
function drawShop()
    -- Draw background
    love.graphics.setColor(0.1, 0.1, 0.1)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    
    -- Draw shop title
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(assets.fonts.title)
    love.graphics.printf("Shop - Level " .. currentLevel, 0, 50, love.graphics.getWidth(), "center")
    
    -- Draw player gold
    love.graphics.setFont(assets.fonts.normal)
    love.graphics.printf("Gold: " .. player.gold, 0, 100, love.graphics.getWidth(), "center")
    
    -- Draw available cards in shop
    for i, card in ipairs(shopCards) do
        local cardX = 100 + (i-1)*120
        local cardY = 200
        
        -- Draw card image
        love.graphics.draw(assets.images[card.name:upper():gsub(" ", "_")], cardX, cardY)
        
        -- Draw card hover effect
        local mouseX, mouseY = love.mouse.getPosition()
        if mouseX >= cardX and mouseX <= cardX + 100 and mouseY >= cardY and mouseY <= cardY + 150 then
            love.graphics.setColor(1, 1, 1, 0.2)
            love.graphics.rectangle("fill", cardX, cardY, 100, 150)
            -- Draw card description
            love.graphics.setColor(1, 1, 1)
            love.graphics.setFont(assets.fonts.small)
            love.graphics.printf(card.description, cardX, cardY - 30, 100, "center")
        end
    end
    
    -- Draw continue button
    local buttonX = love.graphics.getWidth() / 2 - 100
    local buttonY = 450
    local mouseX, mouseY = love.mouse.getPosition()
    
    if mouseX >= buttonX and mouseX <= buttonX + 200 and mouseY >= buttonY and mouseY <= buttonY + 50 then
        love.graphics.setColor(0.8, 0.8, 0.8)
        buttonHover = "continue"
    else
        love.graphics.setColor(0.5, 0.5, 0.5)
        buttonHover = nil
    end
    
    love.graphics.rectangle("fill", buttonX, buttonY, 200, 50)
    love.graphics.setColor(0, 0, 0)
    love.graphics.setFont(assets.fonts.normal)
    love.graphics.printf("Continue to Battle", buttonX, buttonY + 15, 200, "center")
end

-- Draw game over screen
function drawGameOver()
    -- Draw background
    love.graphics.setColor(0.1, 0.1, 0.1)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    
    -- Draw game over message
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(assets.fonts.title)
    love.graphics.printf("Game Over", 0, 200, love.graphics.getWidth(), "center")
    
    love.graphics.setFont(assets.fonts.normal)
    love.graphics.printf(gameOverMessage, 0, 250, love.graphics.getWidth(), "center")
    
    -- Draw restart button
    local buttonX = love.graphics.getWidth() / 2 - 100
    local buttonY = 300
    local mouseX, mouseY = love.mouse.getPosition()
    
    if mouseX >= buttonX and mouseX <= buttonX + 200 and mouseY >= buttonY and mouseY <= buttonY + 50 then
        love.graphics.setColor(0.8, 0.8, 0.8)
        buttonHover = "restart"
    else
        love.graphics.setColor(0.5, 0.5, 0.5)
        buttonHover = nil
    end
    
    love.graphics.rectangle("fill", buttonX, buttonY, 200, 50)
    love.graphics.setColor(0, 0, 0)
    love.graphics.setFont(assets.fonts.normal)
    love.graphics.printf("Restart Game", buttonX, buttonY + 15, 200, "center")
end

-- Handle menu clicks
function handleMenuClick(x, y)
    if y > 300 and y < 350 then
        currentState = GAME_STATE.BATTLE
        startNewBattle()
    end
end

-- Handle battle clicks
function handleBattleClick(x, y)
    if not playerTurn then return end
    
    -- Check if a card was clicked
    local screenWidth = love.graphics.getWidth()
    local cardWidth = 100
    local cardSpacing = 20
    local totalCards = #player.hand
    local totalWidth = (totalCards * cardWidth) + ((totalCards - 1) * cardSpacing)
    local startX = (screenWidth - totalWidth) / 2
    
    for i, card in ipairs(player.hand) do
        local cardX = startX + ((i-1) * (cardWidth + cardSpacing))
        local cardY = 500
        if x >= cardX and x <= cardX + cardWidth and y >= cardY and y <= cardY + 150 then
            if player.energy >= card.cost then
                playCard(card, i)
                playerTurn = false
                -- Enemy will play after a short delay
                love.timer.after(1, enemyTurn)
            end
        end
    end
end

-- Handle shop clicks
function handleShopClick(x, y)
    -- Check if a shop card was clicked
    for i, card in ipairs(shopCards) do
        local cardX = 100 + (i-1)*120
        local cardY = 200
        if x >= cardX and x <= cardX + 100 and y >= cardY and y <= cardY + 150 then
            if player.gold >= card.cost then
                player.gold = player.gold - card.cost
                table.insert(player.deck, card)
                table.remove(shopCards, i)
                return
            end
        end
    end
end

-- Start a new battle
function startNewBattle()
    local isBoss = currentLevel % 10 == 0
    
    if isBoss then
        currentState = GAME_STATE.BOSS_BATTLE
        currentEnemy = createBoss()
        animations.bossIntro.timer = animations.bossIntro.duration
        screenShake.timer = 1
    else
        currentState = GAME_STATE.BATTLE
        currentEnemy = createNormalEnemy()
    end
    
    -- Reset player energy
    player.energy = player.maxEnergy
    
    -- Clear card effects
    cardEffects = {}
    
    -- Draw new hand
    drawHand()
    
    -- Set player turn
    playerTurn = true
    
    -- Generate shop cards
    generateShopCards()
    
    -- Debug print
    print("Starting battle with " .. #player.hand .. " cards")
end

-- Create a normal enemy with scaling difficulty
function createNormalEnemy()
    local healthScaling = 1 + (currentLevel * 0.15)  -- 15% increase per level
    local damageScaling = 1 + (currentLevel * 0.1)   -- 10% increase per level
    
    return {
        health = math.floor(50 * healthScaling),
        maxHealth = math.floor(50 * healthScaling),
        damage = math.floor(5 * damageScaling),
        deck = generateEnemyDeck(),
        hand = {},
        attackBoost = 0,
        defenseBoost = 0,
        isBoss = false
    }
end

-- Create a boss enemy
function createBoss()
    local bossLevel = math.floor(currentLevel / 10)
    local healthScaling = 2 + (bossLevel * 0.5)  -- 50% increase per boss level
    local damageScaling = 1.5 + (bossLevel * 0.3)  -- 30% increase per boss level
    
    return {
        health = math.floor(100 * healthScaling),
        maxHealth = math.floor(100 * healthScaling),
        damage = math.floor(10 * damageScaling),
        deck = generateBossDeck(),
        hand = {},
        attackBoost = 0,
        defenseBoost = 0,
        isBoss = true
    }
end

-- Generate enemy deck based on level
function generateEnemyDeck()
    local deck = {}
    local possibleCards = {
        CARD_TYPES.ATTACK,
        CARD_TYPES.DEFEND,
        CARD_TYPES.HEAL,
        CARD_TYPES.BOOST_ATTACK,
        CARD_TYPES.BOOST_DEFENSE
    }
    
    -- More cards as level increases
    local numCards = 5 + math.floor(currentLevel * 0.5)
    
    for i = 1, numCards do
        local randomCard = possibleCards[love.math.random(1, #possibleCards)]
        table.insert(deck, randomCard)
    end
    
    return deck
end

-- Generate boss deck
function generateBossDeck()
    local deck = {}
    local possibleCards = {
        CARD_TYPES.ATTACK,
        CARD_TYPES.DEFEND,
        CARD_TYPES.HEAL,
        CARD_TYPES.BOOST_ATTACK,
        CARD_TYPES.BOOST_DEFENSE,
        CARD_TYPES.HEAVY_ATTACK,
        CARD_TYPES.MASS_HEAL
    }
    
    -- Bosses have more and better cards
    local numCards = 8 + math.floor(currentLevel / 10)
    
    for i = 1, numCards do
        local randomCard = possibleCards[love.math.random(1, #possibleCards)]
        table.insert(deck, randomCard)
    end
    
    return deck
end

-- Generate shop cards
function generateShopCards()
    shopCards = {}
    local possibleCards = {
        CARD_TYPES.ATTACK,
        CARD_TYPES.DEFEND,
        CARD_TYPES.HEAL,
        CARD_TYPES.BOOST_ATTACK,
        CARD_TYPES.BOOST_DEFENSE
    }
    
    -- Add powerful cards to shop based on level
    if currentLevel >= 5 then
        table.insert(possibleCards, CARD_TYPES.HEAVY_ATTACK)
    end
    if currentLevel >= 7 then
        table.insert(possibleCards, CARD_TYPES.MASS_HEAL)
    end
    
    for i = 1, 3 do
        local randomCard = possibleCards[love.math.random(1, #possibleCards)]
        table.insert(shopCards, randomCard)
    end
end

-- Play a card
function playCard(card, index)
    -- Use energy
    player.energy = player.energy - card.cost
    
    -- Add floating text for energy cost
    addFloatingText("-" .. card.cost, player.x, player.y - 50, assets.colors.energy)
    
    -- Apply card effects
    if card.damage then
        local damage = card.damage + player.attackBoost
        if card.hits then
            for i = 1, card.hits do
                currentEnemy.health = currentEnemy.health - damage
                addFloatingText("-" .. damage, 800, 300, assets.colors.attack)
                addParticleEffect(800, 300, assets.colors.attack, 10)
            end
        else
            currentEnemy.health = currentEnemy.health - damage
            addFloatingText("-" .. damage, 800, 300, assets.colors.attack)
            addParticleEffect(800, 300, assets.colors.attack, 10)
            animations.damage.timer = animations.damage.duration
            screenShake.timer = 0.2
        end
    end
    
    if card.healing then
        player.health = math.min(player.maxHealth, player.health + card.healing)
        addFloatingText("+" .. card.healing, player.x, player.y - 50, assets.colors.health)
        addParticleEffect(player.x, player.y, assets.colors.health, 10)
        animations.heal.timer = animations.heal.duration
    end
    
    if card.block then
        player.defenseBoost = player.defenseBoost + card.block
        addFloatingText("+" .. card.block, player.x, player.y - 50, assets.colors.defense)
        addParticleEffect(player.x, player.y, assets.colors.defense, 10)
    end
    
    if card.attackBoost then
        player.attackBoost = player.attackBoost + card.attackBoost
        addFloatingText("+" .. card.attackBoost, player.x, player.y - 50, assets.colors.attack)
        addParticleEffect(player.x, player.y, assets.colors.attack, 10)
    end
    
    if card.defenseBoost then
        player.defenseBoost = player.defenseBoost + card.defenseBoost
        addFloatingText("+" .. card.defenseBoost, player.x, player.y - 50, assets.colors.defense)
        addParticleEffect(player.x, player.y, assets.colors.defense, 10)
    end
    
    -- Remove card from hand
    table.remove(player.hand, index)
    
    -- Check if enemy is defeated
    if currentEnemy.health <= 0 then
        -- Give gold reward
        local reward = currentEnemy.isBoss and 50 or 20
        player.gold = player.gold + reward
        addFloatingText("+" .. reward .. " gold", player.x, player.y - 70, assets.colors.gold)
        animations.goldGain.timer = animations.goldGain.duration
        
        currentLevel = currentLevel + 1
        currentState = GAME_STATE.SHOP
    end
end

-- Enemy turn
function enemyTurn()
    if not currentEnemy then return end
    
    -- Draw enemy hand
    currentEnemy.hand = {}
    local numCards = currentEnemy.isBoss and 4 or 3  -- Boss draws more cards
    
    for i = 1, numCards do
        if #currentEnemy.deck > 0 then
            local randomIndex = love.math.random(1, #currentEnemy.deck)
            table.insert(currentEnemy.hand, currentEnemy.deck[randomIndex])
            table.remove(currentEnemy.deck, randomIndex)
        end
    end
    
    -- AI: Choose best card based on situation
    local bestCard = nil
    local bestCardIndex = 1
    
    for i, card in ipairs(currentEnemy.hand) do
        if not bestCard then
            bestCard = card
            bestCardIndex = i
        else
            -- Boss AI is smarter
            if currentEnemy.isBoss then
                -- Prioritize healing when low health
                if currentEnemy.health < currentEnemy.maxHealth * 0.4 and card.healing then
                    bestCard = card
                    bestCardIndex = i
                -- Prioritize defense when player has high attack
                elseif player.attackBoost > 5 and card.defenseBoost then
                    bestCard = card
                    bestCardIndex = i
                -- Use heavy attacks when player is vulnerable
                elseif card.damage and card.damage > (bestCard.damage or 0) and player.defenseBoost < 3 then
                    bestCard = card
                    bestCardIndex = i
                end
            else
                -- Normal enemy AI (existing logic)
                if currentEnemy.health < currentEnemy.maxHealth * 0.3 and card.healing then
                    bestCard = card
                    bestCardIndex = i
                elseif player.attackBoost > 5 and card.defenseBoost then
                    bestCard = card
                    bestCardIndex = i
                elseif card.damage and card.damage > (bestCard.damage or 0) then
                    bestCard = card
                    bestCardIndex = i
                end
            end
        end
    end
    
    -- Play the chosen card
    if bestCard then
        if bestCard.damage then
            local damage = bestCard.damage + currentEnemy.attackBoost
            player.health = player.health - math.max(0, damage - player.defenseBoost)
            addFloatingText("-" .. math.max(0, damage - player.defenseBoost), player.x, player.y - 50, assets.colors.attack)
            addParticleEffect(player.x, player.y, assets.colors.attack, 10)
            animations.damage.timer = animations.damage.duration
            screenShake.timer = 0.2
        end
        if bestCard.healing then
            currentEnemy.health = math.min(currentEnemy.maxHealth, currentEnemy.health + bestCard.healing)
            addFloatingText("+" .. bestCard.healing, 800, 300, assets.colors.health)
            addParticleEffect(800, 300, assets.colors.health, 10)
            animations.heal.timer = animations.heal.duration
        end
        if bestCard.block then
            currentEnemy.defenseBoost = currentEnemy.defenseBoost + bestCard.block
            addFloatingText("+" .. bestCard.block, 800, 300, assets.colors.defense)
            addParticleEffect(800, 300, assets.colors.defense, 10)
        end
        if bestCard.attackBoost then
            currentEnemy.attackBoost = currentEnemy.attackBoost + bestCard.attackBoost
            addFloatingText("+" .. bestCard.attackBoost, 800, 300, assets.colors.attack)
            addParticleEffect(800, 300, assets.colors.attack, 10)
        end
        if bestCard.defenseBoost then
            currentEnemy.defenseBoost = currentEnemy.defenseBoost + bestCard.defenseBoost
            addFloatingText("+" .. bestCard.defenseBoost, 800, 300, assets.colors.defense)
            addParticleEffect(800, 300, assets.colors.defense, 10)
        end
        
        table.remove(currentEnemy.hand, bestCardIndex)
    end
    
    -- Check if player is defeated
    if player.health <= 0 then
        currentState = GAME_STATE.GAME_OVER
        gameOverMessage = "You reached level " .. currentLevel
    else
        playerTurn = true
        player.energy = player.maxEnergy
    end
end

-- Update battle state
function updateBattle(dt)
    -- Update card effects
    for i = #cardEffects, 1, -1 do
        cardEffects[i].timer = cardEffects[i].timer - dt
        if cardEffects[i].timer <= 0 then
            table.remove(cardEffects, i)
        end
    end
end

-- Update shop state
function updateShop(dt)
    -- Add shop logic here
end

-- Reset game
function resetGame()
    player.health = player.maxHealth
    player.attackBoost = 0
    player.defenseBoost = 0
    player.gold = 100
    currentLevel = 1
    player.deck = {
        CARD_TYPES.ATTACK,
        CARD_TYPES.ATTACK,
        CARD_TYPES.DEFEND,
        CARD_TYPES.DEFEND
    }
    currentState = GAME_STATE.BATTLE
    startNewBattle()
end

-- Add floating text
function addFloatingText(text, x, y, color, duration)
    table.insert(floatingText, {
        text = text,
        x = x,
        y = y,
        color = color or {1, 1, 1},
        timer = duration or 1,
        duration = duration or 1
    })
end

-- Add particle effect
function addParticleEffect(x, y, color, count)
    for i = 1, count do
        local angle = love.math.random() * math.pi * 2
        local speed = love.math.random(50, 150)
        table.insert(particleEffects, {
            x = x,
            y = y,
            vx = math.cos(angle) * speed,
            vy = math.sin(angle) * speed,
            color = color,
            timer = 0.5,
            duration = 0.5
        })
    end
end 