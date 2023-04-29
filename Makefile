run-tests:
	nvim --headless -c "PlenaryBustedDirectory tests/ {minimal_init = 'tests/minimal_init.lua', sequential = true}"

run-test:
	nvim --headless -u tests/minimal_init.lua -c "PlenaryBustedFile $(filter-out $@,$(MAKECMDGOALS))"

