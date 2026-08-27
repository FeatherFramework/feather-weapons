FeatherCore = {}
FeatherCore.RPC = {
    Register = function(name, callback, options)
        return exports["feather-core"]:RegisterRPC(name, callback, options)
    end
}
