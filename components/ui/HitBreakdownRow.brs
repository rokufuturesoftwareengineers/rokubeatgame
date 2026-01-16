' Shows perfect/great/good/miss counts

sub init()
    m.bg = m.top.findNode("rowBg")
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

sub onBgColorChanged()
    if m.bg <> invalid then
        m.bg.color = m.top.bgColor
    end if
end sub
