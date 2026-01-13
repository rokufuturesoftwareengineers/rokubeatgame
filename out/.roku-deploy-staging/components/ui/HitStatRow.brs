' HitStatRow.brs
' Hit statistic row for gameplay HUD logic

sub init()
    m.labelNode = m.top.findNode("labelText")
    m.valueNode = m.top.findNode("valueText")
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

sub onStatColorChanged()
    if m.labelNode <> invalid and m.valueNode <> invalid then
        m.labelNode.color = m.top.statColor
        m.valueNode.color = m.top.statColor
    end if
end sub
