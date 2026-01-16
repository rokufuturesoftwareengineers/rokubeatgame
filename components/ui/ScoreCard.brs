' Displays a stat with label above, value below

sub init()
    m.cardBg = m.top.findNode("cardBg")
    m.labelNode = m.top.findNode("labelText")
    m.valueNode = m.top.findNode("valueText")
    
    updateDimensions()
end sub

sub onLabelChanged()
    if m.labelNode <> invalid then
        m.labelNode.text = m.top.label
    end if
end sub

sub onValueChanged()
    if m.valueNode <> invalid then
        m.valueNode.text = m.top.value
    end if
end sub

sub onValueColorChanged()
    if m.valueNode <> invalid then
        m.valueNode.color = m.top.valueColor
    end if
end sub

sub updateDimensions()
    if m.cardBg = invalid then return
    
    padding = 20
    
    ' Card background
    m.cardBg.width = m.top.cardWidth
    m.cardBg.height = m.top.cardHeight
    m.cardBg.translation = [0, 0]
    
    ' Label text
    m.labelNode.translation = [padding, 15]
    
    ' Value text
    m.valueNode.width = m.top.cardWidth - (padding * 2)
    m.valueNode.translation = [padding, 40]
end sub
