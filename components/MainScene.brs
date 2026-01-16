' Central hub - manages game state and screen transitions

sub init()
    print "[MainScene] Initializing..."
    
    ' Detect display resolution (default to 720p if unavailable)
    m.screenWidth = 1280
    m.screenHeight = 720
    
    deviceInfo = CreateObject("roDeviceInfo")
    displaySize = deviceInfo.GetDisplaySize()
    if displaySize <> invalid
        m.screenWidth = displaySize.w
        m.screenHeight = displaySize.h
    end if
    
    print "[MainScene] Screen size: "; m.screenWidth; "x"; m.screenHeight
    
    m.screenContainer = m.top.findNode("screenContainer")
    m.background = m.top.findNode("background")
    
    ' Size background to screen
    if m.background <> invalid
        m.background.width = m.screenWidth
        m.background.height = m.screenHeight
    end if
    
    m.currentScreen = invalid
    m.top.gameState = "START_MENU"
    
    m.songCatalog = loadSongCatalog()
    
    m.top.observeField("gameState", "onGameStateChange")
    
    m.top.setFocus(true)
    showStartMenu()
    
    print "[MainScene] Initialization complete"
end sub

function loadSongCatalog() as Object
    catalog = {songs: []}
    
    jsonPath = "pkg:/assets/songs/song_index.json"
    jsonContent = ReadAsciiFile(jsonPath)
    
    if jsonContent <> "" and jsonContent <> invalid
        parsed = ParseJson(jsonContent)
        if parsed <> invalid and parsed.songs <> invalid
            catalog = parsed
            print "[MainScene] Loaded "; catalog.songs.count(); " songs from catalog"
        end if
    else
        print "[MainScene] No song catalog found, using demo data"
        catalog = getDemoCatalog()
    end if
    
    return catalog
end function

' Fallback data when no songs are installed
function getDemoCatalog() as Object
    return {
        songs: [
            {
                id: "mii_plaza",
                title: "Mii Plaza",
                artist: "Nintendo",
                difficulty: "Normal",
                difficultyRating: 4,
                length: 115,
                beatmapPath: "pkg:/assets/songs/mii_plaza/beatmap.json",
                audioPath: "pkg:/assets/songs/mii_plaza/audio.mp3"
            },
            {
                id: "demo_easy",
                title: "Demo Track - Easy",
                artist: "Roku Osu Mania",
                difficulty: "Easy",
                difficultyRating: 1,
                length: 30,
                beatmapPath: "pkg:/assets/songs/demo_song/beatmap.json",
                audioPath: "pkg:/assets/songs/demo_song/audio.mp3"
            },
            {
                id: "demo_normal",
                title: "Demo Track - Normal",
                artist: "Roku Osu Mania",
                difficulty: "Normal",
                difficultyRating: 3,
                length: 30,
                beatmapPath: "pkg:/assets/songs/demo_song/beatmap.json",
                audioPath: "pkg:/assets/songs/demo_song/audio.mp3"
            },
            {
                id: "demo_hard",
                title: "Demo Track - Hard",
                artist: "Roku Osu Mania",
                difficulty: "Hard",
                difficultyRating: 5,
                length: 30,
                beatmapPath: "pkg:/assets/songs/demo_song/beatmap.json",
                audioPath: "pkg:/assets/songs/demo_song/audio.mp3"
            }
        ]
    }
end function

sub onGameStateChange()
    newState = m.top.gameState
    print "[MainScene] State transition to: "; newState
    
    clearCurrentScreen()
    
    if newState = "START_MENU"
        showStartMenu()
    else if newState = "SONG_SELECT"
        showSongSelect()
    else if newState = "PLAYING"
        showGameplay()
    else if newState = "RESULTS"
        showResults()
    end if
end sub

sub clearCurrentScreen()
    if m.currentScreen <> invalid
        m.screenContainer.removeChild(m.currentScreen)
        m.currentScreen = invalid
    end if
end sub

' --- Screen factories ---

sub showStartMenu()
    print "[MainScene] Showing StartMenu"
    m.currentScreen = m.screenContainer.createChild("StartMenu")
    m.currentScreen.observeField("menuAction", "onStartMenuAction")
    m.currentScreen.setFocus(true)
end sub

sub onStartMenuAction()
    action = m.currentScreen.menuAction
    print "[MainScene] StartMenu action: "; action
    
    if action = "play"
        m.top.gameState = "SONG_SELECT"
    else if action = "quit"
        ' Main loop handles the actual exit
    end if
end sub

sub showSongSelect()
    print "[MainScene] Showing SongSelect"
    m.currentScreen = m.screenContainer.createChild("SongSelect")
    m.currentScreen.songCatalog = m.songCatalog
    m.currentScreen.observeField("selectedSong", "onSongSelected")
    m.currentScreen.observeField("action", "onSongSelectAction")
    m.currentScreen.setFocus(true)
end sub

sub onSongSelected()
    song = m.currentScreen.selectedSong
    if song <> invalid
        print "[MainScene] Song selected: "; song.title
        m.top.selectedSong = song
        m.top.gameState = "PLAYING"
    end if
end sub

sub onSongSelectAction()
    action = m.currentScreen.action
    if action = "back"
        m.top.gameState = "START_MENU"
    end if
end sub

sub showGameplay()
    print "[MainScene] Showing GameplayScene"
    m.currentScreen = m.screenContainer.createChild("GameplayScene")
    m.currentScreen.songData = m.top.selectedSong
    m.currentScreen.observeField("gameResult", "onGameFinished")
    m.currentScreen.observeField("action", "onGameplayAction")
    m.currentScreen.setFocus(true)
end sub

sub onGameFinished()
    result = m.currentScreen.gameResult
    if result <> invalid
        print "[MainScene] Game finished - Score: "; result.score
        m.top.gameResults = result
        m.top.gameState = "RESULTS"
    end if
end sub

sub onGameplayAction()
    action = m.currentScreen.action
    if action = "quit"
        m.top.gameState = "SONG_SELECT"
    end if
end sub

sub showResults()
    print "[MainScene] Showing ResultsScreen"
    m.currentScreen = m.screenContainer.createChild("ResultsScreen")
    m.currentScreen.result = m.top.gameResults
    m.currentScreen.songInfo = m.top.selectedSong
    m.currentScreen.observeField("action", "onResultsAction")
    m.currentScreen.setFocus(true)
end sub

sub onResultsAction()
    action = m.currentScreen.action
    if action = "retry"
        m.top.gameState = "PLAYING"
    else if action = "songSelect"
        m.top.gameState = "SONG_SELECT"
    else if action = "mainMenu"
        m.top.gameState = "START_MENU"
    end if
end sub

' Let child screens handle their own input
function onKeyEvent(key as String, press as Boolean) as Boolean
    return false
end function
