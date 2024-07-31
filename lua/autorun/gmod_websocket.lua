if CLIENT then return false end
if SERVER then
    include( "server/websocket_handler.lua" )
    include( "server/websocket_database.lua" )
end