' Receptor.brs
' Lane receptor/target component logic

sub init()
    m.bg = m.top.findNode("receptorBg")
    m.arrowNode = m.top.findNode("receptorArrow")
end sub

sub onArrowChanged()
    if m.arrowNode <> invalid then
        m.arrowNode.text = m.top.arrow
    end if
end sub

sub onArrowColorChanged()
    if m.arrowNode <> invalid then
        m.arrowNode.color = m.top.arrowColor
    end if
end sub

sub onPressedChanged()
    if m.bg = invalid then return

    if m.top.pressed then
        m.bg.color = "0x0f3460FF"
    else
        m.bg.color = "0x0f346080"
    end if
end sub
