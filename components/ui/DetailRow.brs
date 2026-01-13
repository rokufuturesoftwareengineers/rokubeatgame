' DetailRow.brs - Label-value pair component logic (dynamically sized)

sub init()
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
    if m.labelNode = invalid or m.valueNode = invalid then return
    
    m.labelNode.width = m.top.labelWidth
    m.labelNode.translation = [0, 0]
    
    m.valueNode.width = m.top.rowWidth
    m.valueNode.translation = [0, 0]
end sub
