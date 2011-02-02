module Rush
	# Base class for all rush exceptions.
	class Exception < ::RuntimeError; end

	# The entry (file or dir) referenced does not exist.  Message is the entry's full path.
	class DoesNotExist < Exception; end

	# The bash command had a non-zero return value.  Message is stderr.
	class BashFailed < Exception; end

	# There's already an entry by the given name in the given dir.
	class NameAlreadyExists < Exception; end

	# The name cannot contain a slash; use two operations, rename and then move, instead.
	class NameCannotContainSlash < Exception; end

	# You cannot move or copy entries to a path that is not a dir (should end with trailing slash).
	class NotADir < Exception; end

	# A user or permission value specified to set access was not valid.
	class BadAccessSpecifier < Exception; end
end
