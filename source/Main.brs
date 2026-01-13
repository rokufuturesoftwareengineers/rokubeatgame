' Main.brs
' Entry point for Roku Osu Mania
' A 4-key rhythm game inspired by Osu-Mania

sub Main()
    print "========================================"
    print "  Roku Osu Mania - Starting..."
    print "========================================"
    
    ' Initialize the SceneGraph application
    screen = CreateObject("roSGScreen")
    m.port = CreateObject("roMessagePort")
    screen.setMessagePort(m.port)
    
    ' Create the main scene
    scene = screen.CreateScene("MainScene")
    screen.show()
    
    ' Main event loop
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
