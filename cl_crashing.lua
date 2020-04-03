if not CLIENT then return end

local last_ft, last_equality, crashing = 0, 0, false

hook.Add( "Think", "CalculatingCrash", function()
	local current_time = RealTime()
	local current_ft = engine.ServerFrameTime()

	if current_ft == last_ft then
		if last_equality == 0 then
			last_equality = current_time
		elseif last_equality + 5 < current_time then
			if not crashing then
				hook.Run( "CrashStarted" )
			end

			crashing = true
		end
	else
		if crashing then
			hook.Run( "CrashEnded" )
		end

		last_equality = 0
		crashing = false
	end

	last_ft = current_ft
end )

hook.Add( "HUDPaint", "PaintCrashInHUD", function()
	if crashing then
		hook.Run( "PaintCrash", ScrW(), ScrH() )
	end
end )

function IsServerCrashing()
	return crashing
end
