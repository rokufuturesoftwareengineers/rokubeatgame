' Song entry in the song list

sub init()
    m.bg = m.top.findNode("itemBg")
    m.selectionBar = m.top.findNode("selectionBar")
    m.titleLabel = m.top.findNode("titleLabel")
    m.artistLabel = m.top.findNode("artistLabel")
    m.infoGroup = m.top.findNode("infoGroup")
    
    updateDimensions()
end sub

sub onSongTitleChanged()
    if m.titleLabel <> invalid then
        m.titleLabel.text = m.top.songTitle
    end if
end sub

sub onSongArtistChanged()
    if m.artistLabel <> invalid then
        m.artistLabel.text = m.top.songArtist
    end if
end sub

sub onSelectedChanged()
    if m.selectionBar = invalid or m.bg = invalid then return

    if m.top.selected then
        m.selectionBar.visible = true
        m.bg.color = "0x2d343699"
    else
        m.selectionBar.visible = false
        m.bg.color = "0x1a1a2e00"
    end if
end sub

sub updateDimensions()
    if m.bg = invalid then return
    
    ' Background
    m.bg.width = m.top.itemWidth
    m.bg.height = m.top.itemHeight
    
    ' Selection bar (5 pixels wide, full height)
    barWidth = 5
    m.selectionBar.width = barWidth
    m.selectionBar.height = m.top.itemHeight
    m.selectionBar.translation = [0, 0]
    
    ' Info group (offset from selection bar)
    m.infoGroup.translation = [15, 10]
    
    ' Labels width
    labelWidth = m.top.itemWidth - 30  ' Account for padding
    m.titleLabel.width = labelWidth
    m.titleLabel.translation = [0, 0]
    m.artistLabel.width = labelWidth
    m.artistLabel.translation = [0, 25]  ' Below title
end sub
