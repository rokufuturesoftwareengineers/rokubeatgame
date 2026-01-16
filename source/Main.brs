' App entry point - kicks off the SceneGraph UI

sub Main()
    print "========================================"
    print "  Roku Osu Mania - Starting..."
    print "========================================"
    
    screen = CreateObject("roSGScreen")
    m.port = CreateObject("roMessagePort")
    screen.setMessagePort(m.port)
    
    scene = screen.CreateScene("MainScene")
    screen.show()
    ' vscode_rdb_on_device_component_entry
    
    ' Keep the app alive until the user closes it
    while true
        msg = wait(0, m.port)
        msgType = type(msg)
        
        if msgType = "roSGScreenEvent"
            if msg.isScreenClosed()
                print "Screen closed, exiting application..."
                exit while
            end if
        end if
    end while
    
    print "Roku Osu Mania - Goodbye!"
end sub
