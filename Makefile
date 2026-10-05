.PHONY: layout build clean gen

# Lệnh build siêu tốc chỉ dành cho Layout Registry
layout:
	dart run build_runner build -d --build-filter="lib/router/layout_registry.g.dart"

# Lệnh build toàn bộ project (Freezed, Riverpod, GoRouter, Layout...)
build:
	dart run build_runner build -d

# Lệnh build cho một file cụ thể (Dùng: make filter file="path/to/file")
filter:
	dart run build_runner build -d --build-filter="$(file)"

# # Dọn dẹp cache của build_runner
# clean:
# 	dart run build_runner clean

# Hack để nhận tham số trực tiếp (vd: make gen auth, make entity user)
ifeq (gen,$(firstword $(MAKECMDGOALS)))
  GEN_ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
  $(eval $(GEN_ARGS):;@:)
endif

ifeq (entity,$(firstword $(MAKECMDGOALS)))
  ENTITY_ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
  $(eval $(ENTITY_ARGS):;@:)
endif

# Lệnh tạo module mới. Cách dùng: make gen tên_module
# Ví dụ: make gen login
gen:
	dart run ../core_riverpod/lib/generator/generator_module.dart $(GEN_ARGS)

# Lệnh gen entity. Cách dùng: make entity đường_dẫn_file
# Hỗ trợ tự động tìm file (vd: make entity example/model_user.dart)
entity:
	dart run ../core_riverpod/bin/generate_entity.dart $(ENTITY_ARGS)