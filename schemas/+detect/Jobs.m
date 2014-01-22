% detect.Jobs -- job reservation table

%{
detect.Jobs (job)    # the job reservation table
table_name : varchar(255) # className of the table
key_hash   : char(32)     # key hash
-----
status    : enum("reserved","error","ignore") # if tuple is missing, the job is available
error_key=null     : blob                              # non-hashed key for errors only
error_message=""   : varchar(1023)                     # error message returned if failed
error_stack=null   : blob                              # error stack if failed
timestamp=CURRENT_TIMESTAMP : timestamp                # automatic timestamp
%}

classdef Jobs < dj.Relvar
    properties(Constant)
        table = dj.Table('detect.Jobs')
    end
    methods
        function self = Jobs(varargin)
            self.restrict(varargin)
        end
    end
end
