' GradeDisplay.brs - Grade letter display component logic (dynamically sized)

sub init()
    m.bg = m.top.findNode("gradeBg")
    m.labelNode = m.top.findNode("gradeLabel")
    
    updateDimensions()
end sub

sub onGradeChanged()
    if m.labelNode <> invalid then
        m.labelNode.text = m.top.grade
    end if
end sub

sub onGradeColorChanged()
    if m.labelNode <> invalid then
        m.labelNode.color = m.top.gradeColor
    end if
end sub

sub updateDimensions()
    if m.bg = invalid or m.labelNode = invalid then return
    
    size = m.top.displaySize
    
    ' Background
    m.bg.width = size
    m.bg.height = size
    m.bg.translation = [0, 0]
    
    ' Label
    m.labelNode.width = size
    m.labelNode.height = size
    m.labelNode.translation = [0, 0]
end sub
