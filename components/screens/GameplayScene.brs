' GameplayScene.brs
' Core rhythm gameplay - note spawning, hit detection, scoring
' All positions calculated dynamically based on screen size

sub init()
    print "[Gameplay] Initializing..."
    
    ' Get screen dimensions dynamically
    initScreenDimensions()
    
    ' Calculate layout based on screen size
    calculateLayout()
    
    ' Setup all UI elements with dynamic positions
    setupLayout()
    
    ' Get UI references
    m.notesContainer = m.top.findNode("notesContainer")
    m.songTitle = m.top.findNode("songTitle")
    m.songArtist = m.top.findNode("songArtist")
    m.scoreLabel = m.top.findNode("scoreLabel")
    m.accuracyLabel = m.top.findNode("accuracyLabel")
    m.hitFeedback = m.top.findNode("hitFeedback")
    m.comboLabel = m.top.findNode("comboLabel")
    m.perfectCount = m.top.findNode("perfectCount")
    m.goodCount = m.top.findNode("goodCount")
    m.missCount = m.top.findNode("missCount")
    m.progressBar = m.top.findNode("progressBar")
    m.pauseOverlay = m.top.findNode("pauseOverlay")
    m.countdownOverlay = m.top.findNode("countdownOverlay")
    m.countdownText = m.top.findNode("countdownText")
    
    ' Original arrow colors
    m.arrowColors = ["0xe94560FF", "0x00cec9FF", "0xfdcb6eFF", "0x6c5ce7FF"]
    
    ' Timing windows (seconds) - not screen dependent
    m.perfectWindow = 0.05     ' ±50ms
    m.goodWindow = 0.10        ' ±100ms
    
    ' Scoring
    m.perfectPoints = 300
    m.goodPoints = 100
    m.missPoints = 0
    
    ' Game state
    m.isPaused = false
    m.isPlaying = false
    m.isCountingDown = false
    m.gameTime = 0
    m.score = 0
    m.combo = 0
    m.maxCombo = 0
    m.perfects = 0
    m.goods = 0
    m.misses = 0
    m.totalNotes = 0
    
    ' Notes data
    m.beatmap = []
    m.activeNotes = []
    m.nextNoteIndex = 0
    m.songLength = 0
    m.audioPath = ""
    
    ' Audio node for music playback (SceneGraph compatible)
    m.audioNode = CreateObject("roSGNode", "Audio")
    m.audioNode.observeField("state", "onAudioStateChange")
    
    ' Game timer
    m.gameTimer = CreateObject("roSGNode", "Timer")
    m.gameTimer.repeat = true
    m.gameTimer.duration = 0.016  ' ~60fps
    m.gameTimer.observeField("fire", "onGameTick")
    
    ' Countdown timer
    m.countdownTimer = CreateObject("roSGNode", "Timer")
    m.countdownTimer.repeat = true
    m.countdownTimer.duration = 1.0
    m.countdownTimer.observeField("fire", "onCountdownTick")
    m.countdownValue = 3
    
    ' Feedback clear timer
    m.feedbackTimer = CreateObject("roSGNode", "Timer")
    m.feedbackTimer.repeat = false
    m.feedbackTimer.duration = 0.3
    m.feedbackTimer.observeField("fire", "clearFeedback")
    
    ' Receptor flash timers (one per lane)
    m.receptorTimers = []
    for i = 0 to 3
        timer = CreateObject("roSGNode", "Timer")
        timer.repeat = false
        timer.duration = 0.1
        timer.id = i.toStr()
        timer.observeField("fire", "onReceptorTimerFire")
        m.receptorTimers.push(timer)
    end for
    
    m.top.setFocus(true)
    
    print "[Gameplay] Initialization complete - Screen: "; m.screenWidth; "x"; m.screenHeight
end sub

' Initialize screen dimensions
sub initScreenDimensions()
    m.screenWidth = 1280
    m.screenHeight = 720
    
    deviceInfo = CreateObject("roDeviceInfo")
    displaySize = deviceInfo.GetDisplaySize()
    if displaySize <> invalid
        m.screenWidth = displaySize.w
        m.screenHeight = displaySize.h
    end if
    
    ' Calculate scale factor (base resolution is 720p)
    m.scaleFactor = m.screenHeight / 720.0
end sub

' Calculate all layout values based on screen size
sub calculateLayout()
    ' Lane area takes up middle ~42% of screen width
    m.laneAreaWidth = int(m.screenWidth * 0.42)
    m.laneAreaX = int((m.screenWidth - m.laneAreaWidth) / 2)
    
    ' Each lane width
    m.laneWidth = int(m.laneAreaWidth / 4)
    m.lanePositions = []
    for i = 0 to 3
        m.lanePositions.push(m.laneAreaX + (i * m.laneWidth))
    end for
    
    ' Note dimensions (scaled)
    m.noteWidth = int(m.laneWidth * 0.9)
    m.noteHeight = int(m.screenHeight * 0.038)
    
    ' Hit line at 86% from top (shifted down from 75%)
    m.hitLineY = int(m.screenHeight * 0.86)
    
    ' Receptor position - bottom of receptor box aligned with hit line
    m.receptorHeight = int(m.screenHeight * 0.074)
    m.receptorY = int(m.hitLineY - m.receptorHeight)  ' Bottom edge at hit line
    
    ' Note speed scales with screen height
    m.noteSpeed = int(m.screenHeight * 0.556)  ' 400 at 720p
    
    ' Spawn position above screen
    m.spawnY = int(-m.screenHeight * 0.046)
    
    ' Progress bar position (below hit zone)
    m.progressY = int(m.hitLineY + (m.screenHeight * 0.02))
    m.progressHeight = int(m.screenHeight * 0.01)
    
    ' HUD padding
    m.hudPadding = int(m.screenWidth * 0.026)
    m.hudWidth = int(m.screenWidth * 0.23)
end sub

' Setup all UI elements with calculated positions
sub setupLayout()
    ' Background
    background = m.top.findNode("background")
    background.width = m.screenWidth
    background.height = m.screenHeight
    
    ' Lane backdrop
    laneBackdrop = m.top.findNode("laneBackdrop")
    laneBackdrop.translation = [m.laneAreaX, 0]
    laneBackdrop.width = m.laneAreaWidth
    laneBackdrop.height = m.screenHeight
    
    ' Create lane dividers
    setupLaneDividers()
    
    ' Create receptors
    setupReceptors()
    
    ' Feedback area (centered in lane area)
    feedbackArea = m.top.findNode("feedbackArea")
    feedbackX = m.laneAreaX + (m.laneAreaWidth / 2)
    feedbackY = int(m.hitLineY - (m.screenHeight * 0.13))
    feedbackArea.translation = [feedbackX, feedbackY]
    
    hitFeedback = m.top.findNode("hitFeedback")
    hitFeedback.width = int(m.laneAreaWidth * 0.5)
    hitFeedback.translation = [int(-m.laneAreaWidth * 0.25), 0]
    
    comboLabel = m.top.findNode("comboLabel")
    comboLabel.width = int(m.laneAreaWidth * 0.5)
    comboLabel.translation = [int(-m.laneAreaWidth * 0.25), int(m.screenHeight * 0.056)]
    
    ' HUD Left
    setupHudLeft()
    
    ' HUD Right
    setupHudRight()
    
    ' Progress bar
    setupProgressBar()
    
    ' Pause overlay
    setupPauseOverlay()
    
    ' Countdown overlay
    setupCountdownOverlay()
end sub

' Create lane dividers dynamically
sub setupLaneDividers()
    laneDividers = m.top.findNode("laneDividers")
    dividerWidth = int(m.screenWidth * 0.002)
    
    for i = 0 to 4
        divider = laneDividers.createChild("Rectangle")
        divider.width = dividerWidth
        divider.height = m.screenHeight
        divider.color = "0x0f3460FF"
        divider.translation = [m.laneAreaX + (i * m.laneWidth), 0]
    end for
end sub

' Create receptors dynamically
sub setupReceptors()
    receptors = m.top.findNode("receptors")
    receptors.translation = [0, m.receptorY]
    
    arrowSymbols = ["<", "^", "v", ">"]
    arrowColors = ["0xe94560FF", "0x00cec9FF", "0xfdcb6eFF", "0x6c5ce7FF"]
    
    m.receptorBgs = []
    m.receptorArrows = []
    
    ' Arrow offset from top of receptor (move down within receptor box)
    arrowOffsetY = int(m.receptorHeight * 0.15)
    
    for i = 0 to 3
        ' Create receptor group
        receptorGroup = receptors.createChild("Group")
        xPos = m.lanePositions[i] + int((m.laneWidth - m.noteWidth) / 2)
        receptorGroup.translation = [xPos, 0]
        
        ' Background
        bg = receptorGroup.createChild("Rectangle")
        bg.id = "receptor" + i.toStr() + "Bg"
        bg.width = m.noteWidth
        bg.height = m.receptorHeight
        bg.color = "0x0f346080"
        m.receptorBgs.push(bg)
        
        ' Arrow label - shifted down within receptor
        arrow = receptorGroup.createChild("Label")
        arrow.id = "receptor" + i.toStr() + "Arrow"
        arrow.text = arrowSymbols[i]
        arrow.font = "font:MediumBoldSystemFont"
        arrow.color = arrowColors[i]
        arrow.width = m.noteWidth
        arrow.height = m.receptorHeight
        arrow.translation = [0, arrowOffsetY]
        arrow.horizAlign = "center"
        arrow.vertAlign = "center"
        m.receptorArrows.push(arrow)
    end for
end sub

' Setup left HUD
sub setupHudLeft()
    hudLeft = m.top.findNode("hudLeft")
    hudLeft.translation = [m.hudPadding, m.hudPadding]
    
    songTitle = m.top.findNode("songTitle")
    songTitle.width = m.hudWidth
    
    songArtist = m.top.findNode("songArtist")
    songArtist.translation = [0, int(m.screenHeight * 0.038)]
    songArtist.width = m.hudWidth
    
    scoreHeader = m.top.findNode("scoreHeader")
    scoreHeader.translation = [0, int(m.screenHeight * 0.111)]
    
    scoreLabel = m.top.findNode("scoreLabel")
    scoreLabel.translation = [0, int(m.screenHeight * 0.145)]
    scoreLabel.width = m.hudWidth
end sub

' Setup right HUD
sub setupHudRight()
    hudRight = m.top.findNode("hudRight")
    hudRight.translation = [m.screenWidth - m.hudWidth - m.hudPadding, m.hudPadding]
    
    accuracyHeader = m.top.findNode("accuracyHeader")
    accuracyHeader.width = m.hudWidth
    
    accuracyLabel = m.top.findNode("accuracyLabel")
    accuracyLabel.translation = [0, int(m.screenHeight * 0.038)]  ' Shifted down more
    accuracyLabel.width = m.hudWidth
    
    ' Stats group - positioned below accuracy with more space
    statsGroup = m.top.findNode("statsGroup")
    statsGroup.translation = [0, int(m.screenHeight * 0.12)]
    
    rowHeight = int(m.screenHeight * 0.028)  ' Slightly more row height
    labelWidth = int(m.hudWidth * 0.6)       ' Wider labels for full words
    countOffset = int(m.hudWidth * 0.75)     ' Position for count numbers
    
    perfectHeader = m.top.findNode("perfectHeader")
    perfectHeader.width = labelWidth
    perfectHeader.horizAlign = "right"
    
    perfectCount = m.top.findNode("perfectCount")
    perfectCount.translation = [countOffset, 0]
    perfectCount.width = int(m.hudWidth * 0.25)
    perfectCount.horizAlign = "right"
    
    goodHeader = m.top.findNode("goodHeader")
    goodHeader.translation = [0, rowHeight]
    goodHeader.width = labelWidth
    goodHeader.horizAlign = "right"
    
    goodCount = m.top.findNode("goodCount")
    goodCount.translation = [countOffset, rowHeight]
    goodCount.width = int(m.hudWidth * 0.25)
    goodCount.horizAlign = "right"
    
    missHeader = m.top.findNode("missHeader")
    missHeader.translation = [0, rowHeight * 2]
    missHeader.width = labelWidth
    missHeader.horizAlign = "right"
    
    missCount = m.top.findNode("missCount")
    missCount.translation = [countOffset, rowHeight * 2]
    missCount.width = int(m.hudWidth * 0.25)
    missCount.horizAlign = "right"
end sub

' Setup progress bar
sub setupProgressBar()
    progressGroup = m.top.findNode("progressGroup")
    progressGroup.translation = [m.laneAreaX, m.progressY]
    
    progressBg = m.top.findNode("progressBg")
    progressBg.width = m.laneAreaWidth
    progressBg.height = m.progressHeight
    
    progressBar = m.top.findNode("progressBar")
    progressBar.width = 0
    progressBar.height = m.progressHeight
    
    m.progressMaxWidth = m.laneAreaWidth
end sub

' Setup pause overlay
sub setupPauseOverlay()
    pauseBg = m.top.findNode("pauseBg")
    pauseBg.width = m.screenWidth
    pauseBg.height = m.screenHeight
    
    centerX = m.screenWidth / 2
    labelWidth = int(m.screenWidth * 0.21)
    
    pauseTitle = m.top.findNode("pauseTitle")
    pauseTitle.translation = [centerX - labelWidth / 2, int(m.screenHeight * 0.42)]
    pauseTitle.width = labelWidth
    
    pauseResume = m.top.findNode("pauseResume")
    pauseResume.translation = [centerX - labelWidth / 2, int(m.screenHeight * 0.48)]
    pauseResume.width = labelWidth
    
    pauseQuit = m.top.findNode("pauseQuit")
    pauseQuit.translation = [centerX - labelWidth / 2, int(m.screenHeight * 0.53)]
    pauseQuit.width = labelWidth
end sub

' Setup countdown overlay
sub setupCountdownOverlay()
    countdownBg = m.top.findNode("countdownBg")
    countdownBg.width = m.screenWidth
    countdownBg.height = m.screenHeight
    
    countdownText = m.top.findNode("countdownText")
    countdownSize = int(m.screenHeight * 0.185)
    countdownText.width = countdownSize
    countdownText.height = countdownSize
    countdownText.translation = [(m.screenWidth - countdownSize) / 2, int(m.screenHeight * 0.42)]
end sub

' Called when song data is set
sub onSongLoaded()
    songData = m.top.songData
    if songData = invalid then return
    
    print "[Gameplay] Loading song: "; songData.title
    
    m.songTitle.text = songData.title
    m.songArtist.text = songData.artist
    m.songLength = songData.length
    
    ' Store audio path for playback
    if songData.audioPath <> invalid and songData.audioPath <> ""
        m.audioPath = songData.audioPath
        print "[Gameplay] Audio path: "; m.audioPath
    else
        m.audioPath = ""
        print "[Gameplay] No audio path provided"
    end if
    
    loadBeatmap(songData.beatmapPath)
    startCountdown()
end sub

' Load beatmap from file
sub loadBeatmap(beatmapPath as String)
    print "[Gameplay] Loading beatmap: "; beatmapPath
    
    jsonStr = ReadAsciiFile(beatmapPath)
    if jsonStr = ""
        print "[Gameplay] Failed to read beatmap"
        createDemoNotes()
        return
    end if
    
    beatmapData = ParseJson(jsonStr)
    if beatmapData = invalid or beatmapData.notes = invalid
        print "[Gameplay] Invalid beatmap format"
        createDemoNotes()
        return
    end if
    
    m.beatmap = beatmapData.notes
    m.totalNotes = m.beatmap.count()
    
    if beatmapData.offset <> invalid
        m.audioOffset = beatmapData.offset
    else
        m.audioOffset = 0
    end if
    
    print "[Gameplay] Loaded "; m.totalNotes; " notes"
end sub

' Create demo notes for testing
sub createDemoNotes()
    m.beatmap = []
    noteTime = 2.0
    lanes = [0, 1, 2, 3]
    
    for i = 0 to 39
        note = { time: noteTime, lane: lanes[i mod 4] }
        m.beatmap.push(note)
        noteTime = noteTime + 0.5
    end for
    
    m.totalNotes = m.beatmap.count()
    print "[Gameplay] Created "; m.totalNotes; " demo notes"
end sub

' Start countdown before gameplay
sub startCountdown()
    m.isCountingDown = true
    m.countdownValue = 3
    m.countdownOverlay.visible = true
    m.countdownText.text = m.countdownValue.toStr()
    m.countdownTimer.control = "start"
end sub

' Countdown timer tick
sub onCountdownTick()
    m.countdownValue = m.countdownValue - 1
    
    if m.countdownValue > 0
        m.countdownText.text = m.countdownValue.toStr()
    else if m.countdownValue = 0
        m.countdownText.text = "GO!"
    else
        m.countdownTimer.control = "stop"
        m.countdownOverlay.visible = false
        m.isCountingDown = false
        startGameplay()
    end if
end sub

' Start actual gameplay
sub startGameplay()
    print "[Gameplay] Starting gameplay!"
    
    m.isPlaying = true
    m.gameTime = 0
    m.nextNoteIndex = 0
    m.score = 0
    m.combo = 0
    m.perfects = 0
    m.goods = 0
    m.misses = 0
    
    updateHUD()
    
    ' Start audio playback if audio path is set
    startAudio()
    
    m.gameTimer.control = "start"
end sub

' Start audio playback
sub startAudio()
    if m.audioPath = "" or m.audioPath = invalid
        print "[Gameplay] No audio to play"
        return
    end if
    
    print "[Gameplay] Starting audio: "; m.audioPath
    
    ' Create content node for Audio
    contentNode = CreateObject("roSGNode", "ContentNode")
    contentNode.url = m.audioPath
    
    m.audioNode.content = contentNode
    m.audioNode.control = "play"
end sub

' Stop audio playback
sub stopAudio()
    if m.audioNode <> invalid
        m.audioNode.control = "stop"
        print "[Gameplay] Audio stopped"
    end if
end sub

' Pause audio playback
sub pauseAudio()
    if m.audioNode <> invalid
        m.audioNode.control = "pause"
        print "[Gameplay] Audio paused"
    end if
end sub

' Resume audio playback
sub resumeAudio()
    if m.audioNode <> invalid
        m.audioNode.control = "resume"
        print "[Gameplay] Audio resumed"
    end if
end sub

' Audio state change handler
sub onAudioStateChange()
    state = m.audioNode.state
    print "[Gameplay] Audio state: "; state
end sub

' Main game loop tick
sub onGameTick()
    if not m.isPlaying or m.isPaused then return
    
    m.gameTime = m.gameTime + 0.016
    spawnNotes()
    updateNotes()
    checkMissedNotes()
    updateProgress()
    checkSongEnd()
end sub

' Spawn notes that are approaching
sub spawnNotes()
    travelTime = (m.hitLineY - m.spawnY) / m.noteSpeed
    lookAheadTime = m.gameTime + travelTime
    
    while m.nextNoteIndex < m.beatmap.count()
        note = m.beatmap[m.nextNoteIndex]
        
        if note.time <= lookAheadTime
            spawnNote(note)
            m.nextNoteIndex = m.nextNoteIndex + 1
        else
            exit while
        end if
    end while
end sub

' Create a visual note
sub spawnNote(noteData as Object)
    noteNode = m.notesContainer.createChild("Rectangle")
    noteNode.width = m.noteWidth
    noteNode.height = m.noteHeight
    
    lane = noteData.lane
    if lane < 0 then lane = 0
    if lane > 3 then lane = 3
    
    xPos = m.lanePositions[lane] + int((m.laneWidth - m.noteWidth) / 2)
    noteNode.translation = [xPos, m.spawnY]
    
    laneColors = ["0xe94560FF", "0x00cec9FF", "0xfdcb6eFF", "0x6c5ce7FF"]
    noteNode.color = laneColors[lane]
    
    activeNote = { node: noteNode, time: noteData.time, lane: lane, hit: false }
    m.activeNotes.push(activeNote)
end sub

' Update positions of active notes
sub updateNotes()
    for each note in m.activeNotes
        if note.node <> invalid and not note.hit
            timeUntilHit = note.time - m.gameTime
            yPos = m.hitLineY - (timeUntilHit * m.noteSpeed)
            currentX = note.node.translation[0]
            note.node.translation = [currentX, yPos]
        end if
    end for
end sub

' Check for notes that were missed
sub checkMissedNotes()
    missThreshold = m.hitLineY + int(m.screenHeight * 0.14)
    
    i = 0
    while i < m.activeNotes.count()
        note = m.activeNotes[i]
        
        if note.node <> invalid and not note.hit
            yPos = note.node.translation[1]
            
            if yPos > missThreshold
                registerMiss(note)
                removeNote(i)
            else
                i = i + 1
            end if
        else
            i = i + 1
        end if
    end while
end sub

' Handle lane key press
sub pressLane(lane as Integer)
    if not m.isPlaying or m.isPaused then return
    
    flashReceptor(lane)
    
    closestNote = invalid
    closestIndex = -1
    closestTimeDiff = 999
    
    for i = 0 to m.activeNotes.count() - 1
        note = m.activeNotes[i]
        
        if note.lane = lane and not note.hit
            timeDiff = absoluteValue(note.time - m.gameTime)
            
            if timeDiff < closestTimeDiff
                closestTimeDiff = timeDiff
                closestNote = note
                closestIndex = i
            end if
        end if
    end for
    
    if closestNote <> invalid
        if closestTimeDiff <= m.perfectWindow
            registerPerfect(closestNote)
            removeNote(closestIndex)
        else if closestTimeDiff <= m.goodWindow
            registerGood(closestNote)
            removeNote(closestIndex)
        end if
    end if
end sub

' Register a perfect hit
sub registerPerfect(note as Object)
    m.combo = m.combo + 1
    if m.combo > m.maxCombo then m.maxCombo = m.combo
    
    comboMult = 1.0 + (m.combo * 0.01)
    points = int(m.perfectPoints * comboMult)
    m.score = m.score + points
    m.perfects = m.perfects + 1
    
    showFeedback("PERFECT!", "0x6c5ce7FF")
    updateHUD()
end sub

' Register a good hit
sub registerGood(note as Object)
    m.combo = m.combo + 1
    if m.combo > m.maxCombo then m.maxCombo = m.combo
    
    comboMult = 1.0 + (m.combo * 0.01)
    points = int(m.goodPoints * comboMult)
    m.score = m.score + points
    m.goods = m.goods + 1
    
    showFeedback("GOOD", "0x00b894FF")
    updateHUD()
end sub

' Register a miss
sub registerMiss(note as Object)
    m.combo = 0
    m.misses = m.misses + 1
    
    showFeedback("MISS", "0xd63031FF")
    updateHUD()
end sub

' Remove note from active list
sub removeNote(index as Integer)
    if index >= 0 and index < m.activeNotes.count()
        note = m.activeNotes[index]
        if note.node <> invalid
            note.node.getParent().removeChild(note.node)
        end if
        m.activeNotes.delete(index)
    end if
end sub

' Flash receptor when pressed
sub flashReceptor(lane as Integer)
    if lane >= 0 and lane <= 3
        m.receptorBgs[lane].color = "0xFFFFFFFF"
        m.receptorArrows[lane].color = "0xFFFFFFFF"
        m.receptorTimers[lane].control = "stop"
        m.receptorTimers[lane].control = "start"
    end if
end sub

' Timer callback to reset receptor color
sub onReceptorTimerFire(event as Object)
    timer = event.getRoSGNode()
    lane = timer.id.toInt()
    if lane >= 0 and lane <= 3
        m.receptorBgs[lane].color = "0x0f346080"
        m.receptorArrows[lane].color = m.arrowColors[lane]
    end if
end sub

' Show hit feedback text
sub showFeedback(feedbackText as String, color as String)
    m.hitFeedback.text = feedbackText
    m.hitFeedback.color = color
    m.comboLabel.text = m.combo.toStr() + "x COMBO"
    
    m.feedbackTimer.control = "stop"
    m.feedbackTimer.control = "start"
end sub

' Clear feedback text
sub clearFeedback()
    m.hitFeedback.text = ""
end sub

' Update HUD elements
sub updateHUD()
    m.scoreLabel.text = m.score.toStr()
    m.perfectCount.text = m.perfects.toStr()
    m.goodCount.text = m.goods.toStr()
    m.missCount.text = m.misses.toStr()
    
    totalHits = m.perfects + m.goods + m.misses
    if totalHits > 0
        accuracy = ((m.perfects * 100.0) + (m.goods * 50.0)) / totalHits
        m.accuracyLabel.text = formatNumber(accuracy, 2) + "%"
    else
        m.accuracyLabel.text = "100.00%"
    end if
end sub

' Format number with decimals
function formatNumber(num as Float, decimals as Integer) as String
    mult = 1
    for i = 1 to decimals
        mult = mult * 10
    end for
    rounded = int(num * mult + 0.5) / mult
    return str(rounded).trim()
end function

' Update progress bar
sub updateProgress()
    if m.songLength > 0
        progress = m.gameTime / m.songLength
        if progress > 1 then progress = 1
        m.progressBar.width = int(m.progressMaxWidth * progress)
    end if
end sub

' Check if song has ended
sub checkSongEnd()
    if m.nextNoteIndex >= m.beatmap.count() and m.activeNotes.count() = 0
        endGame()
    else if m.gameTime > m.songLength + 2
        endGame()
    end if
end sub

' End the game
sub endGame()
    print "[Gameplay] Game ended!"
    
    m.isPlaying = false
    m.gameTimer.control = "stop"
    
    ' Stop audio playback
    stopAudio()
    
    for each note in m.activeNotes
        if note.node <> invalid
            note.node.getParent().removeChild(note.node)
        end if
    end for
    m.activeNotes = []
    
    grade = calculateGrade()
    
    songData = m.top.songData
    if songData <> invalid
        saveHighScore(songData.id, m.score)
    end if
    
    result = {
        score: m.score,
        grade: grade,
        perfects: m.perfects,
        goods: m.goods,
        misses: m.misses,
        maxCombo: m.maxCombo,
        totalNotes: m.totalNotes,
        accuracy: calculateAccuracy()
    }
    
    print "[Gameplay] Result: "; result.grade; " - Score: "; m.score
    m.top.gameResult = result
end sub

' Calculate grade based on accuracy
function calculateGrade() as String
    accuracy = calculateAccuracy()
    
    if accuracy >= 95 then return "S"
    if accuracy >= 90 then return "A"
    if accuracy >= 80 then return "B"
    if accuracy >= 70 then return "C"
    if accuracy >= 60 then return "D"
    return "F"
end function

' Calculate accuracy percentage
function calculateAccuracy() as Float
    totalHits = m.perfects + m.goods + m.misses
    if totalHits = 0 then return 100.0
    return ((m.perfects * 100.0) + (m.goods * 50.0)) / totalHits
end function

' Save high score to registry
sub saveHighScore(songId as String, newScore as Integer)
    section = CreateObject("roRegistrySection", "highscores")
    currentScore = section.Read(songId)
    
    if currentScore = "" or newScore > currentScore.toInt()
        section.Write(songId, newScore.toStr())
        section.Flush()
        print "[Gameplay] New high score saved: "; newScore
    end if
end sub

' Toggle pause
sub togglePause()
    m.isPaused = not m.isPaused
    m.pauseOverlay.visible = m.isPaused
    
    ' Pause/resume audio
    if m.isPaused
        pauseAudio()
    else
        resumeAudio()
    end if
end sub

' Absolute value helper
function absoluteValue(num as Float) as Float
    if num < 0 then return -num
    return num
end function

' Handle remote input
function onKeyEvent(key as String, press as Boolean) as Boolean
    if not press then return false
    
    if m.isCountingDown then return true
    
    if m.isPaused
        if key = "OK"
            togglePause()
            return true
        else if key = "back"
            m.gameTimer.control = "stop"
            stopAudio()
            m.top.action = "quit"
            return true
        end if
        return true
    end if
    
    if m.isPlaying
        if key = "left"
            pressLane(0)
            return true
        else if key = "up"
            pressLane(1)
            return true
        else if key = "down"
            pressLane(2)
            return true
        else if key = "right"
            pressLane(3)
            return true
        else if key = "play" or key = "pause" or key = "OK"
            togglePause()
            return true
        else if key = "back"
            togglePause()
            return true
        end if
    end if
    
    return false
end function
