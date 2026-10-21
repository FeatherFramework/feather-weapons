dofile('shared/constants.lua')
local E=WeaponNativeEnrollment
local jane='6a2fd060-c46f-11f1-9ae2-e0d55eaa2deb'
local second='e5e9955d-c29e-11f1-9ae2-e0d55eaa2deb'
local third='aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee'
local config={NativeAlphaCharacterId=jane}
assert(E.Allows(config,jane) and not E.Allows(config,second))
config.NativeAlphaAdditionalCharacters={[second]=true}
assert(E.Allows(config,jane) and E.Allows(config,second) and not E.Allows(config,third))
local members=assert(E.Validate(config)); members[third]=true
assert(not E.Allows(config,third),'returned snapshots cannot mutate configuration')
config.NativeAlphaAdditionalCharacters[jane]=true
assert(E.Validate(config),'duplicate legacy member does not consume another enrollment')
config.NativeAlphaAdditionalCharacters[third]=true
assert(not E.Validate(config) and not E.Allows(config,jane),'overlimit invalidates entire policy')
assert(E.Allows({NativeAlphaCharacterId=jane,NativeAlphaAdditionalCharacters={}},jane))
for _,bad in ipairs({false,1,'*', {second}, {[second]=false}, {['*']=true}, {[third:sub(1,35)]=true}}) do
 config.NativeAlphaAdditionalCharacters=bad
 assert(not E.Validate(config) and not E.Allows(config,jane),'invalid list must not partially authorize legacy member')
end
assert(not E.Validate({}) and not E.Validate(false))
assert(not E.Validate({NativeAlphaCharacterId=''}) and not E.Allows(config,nil))
assert(E.Allows({NativeAlphaAdditionalCharacters={[jane]=true,[second]=true}},second))
assert(E.Allows({NativeAlphaCharacterId='legacy-test-alias'},'legacy-test-alias'),'preserve prior explicit singleton semantics')
print('Native enrollment pure policy PASS (legacy compatibility, exact two-member bound, malformed fail-closed, no shared mutable snapshot)')
