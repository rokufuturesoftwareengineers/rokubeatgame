' MenuButton.brs
' Reusable button component logic

sub init()
    m.bg = m.top.findNode("buttonBg")
    m.labelNode = m.top.findNode("buttonLabel")

    ' Set initial colors
    m.primaryColor = "0x6c5ce7FF"
    m.secondaryColor = "0x2d3436FF"
    m.primaryTextColor = "0xFFFFFFFF"
    m.secondaryTextColor = "0xb2bec3FF"

    updateColors()
    updateDimensions()
end sub

sub onLabelChanged()
    if m.labelNode <> invalid then
        m.labelNode.text = m.top.label
    end if
end sub

sub updateColors()
    if m.bg = invalid then return

    if m.top.primary then
        m.primaryColor = "0x6c5ce7FF"
        m.primaryTextColor = "0xFFFFFFFF"
    else
        m.primaryColor = "0x2d3436FF"
        m.primaryTextColor = "0xb2bec3FF"
    end if

    onSelectedChanged()
end sub

sub onSelectedChanged()
    if m.bg = invalid then return

    if m.top.selected then
        m.bg.color = m.primaryColor
        m.labelNode.color = m.primaryTextColor
    else
        m.bg.color = m.secondaryColor
        m.labelNode.color = m.secondaryTextColor
    end if
end sub

sub updateDimensions()
    if m.bg = invalid or m.labelNode = invalid then return
    
    m.bg.width = m.top.buttonWidth
    m.bg.height = m.top.buttonHeight
    m.labelNode.width = m.top.buttonWidth
    m.labelNode.height = m.top.buttonHeight
end sub
