%{
ae.TetrodeImplants (manual) # tetrode drive implants

-> acq.Subjects
implant_num     : tinyint unsigned # implant number
---
hemisphere      : enum("left", "right") # hemisphere
area            : varchar(45)   # target area
implant_date    : date     # date of implant surgery
%}

classdef TetrodeImplants < dj.Relvar
    properties (Constant)
        table = dj.Table('ae.TetrodeImplants');
    end
    
    methods
        function addTetrodes(self, tetrodes, x, y, materials)
            % Add tetrodes to implant.
            %   addTetrodes(relvar, tetrodes, x, y, materials) adds the
            %   specified tetrodes to the implant given by relvar. The
            %   inputs x, y and materials are arrays/cell arrays of the
            %   same length as tetrodes. materials can be a string in case
            %   all tetrodes are made of the same material.
            
            assert(count(self) == 1, 'relvar must be scalar!')
            assert(numel(tetrodes) == numel(x) && numel(x) == numel(y) && ...
                (numel(y) == numel(materials) || ischar(materials)), ...
                'tetrode properties have inconsistent lengths!')
            key = fetch(self);
            for i = 1 : numel(tetrodes)
                tuple = key;
                tuple.electrode_num = tetrodes(i);
                tuple.loc_x = x(i);
                tuple.loc_y = y(i);
                if ischar(materials)
                    tuple.material = materials;
                else
                    tuple.material = materials{i};
                end
                insert(ae.TetrodeProperties, tuple);
            end
        end
        
        
        function linkEphys(self, ephysKeys)
            % Link ephys session to implant.
            %   linkEphys(relvar, ephysKeys) links the given ephys
            %   session(s) to the implant defined by relvar.
            
            assert(count(self) == 1, 'relvar must be scalar!')
            if ~isstruct(ephysKeys)
                ephysKeys = fetch(ephysKeys);
            end
            tuples = fetch(self * acq.Ephys & ephysKeys);
            insert(ae.TetrodeImplantsEphysLink, tuples);
        end
        
    end
    
    methods (Static)
        function addImplant(subject, implantNum, hemisphere, area, date)
            % Add implant.
            %   addImplant(subject, implantNum, hemisphere, area, date)
            %   adds an implant to the database. The subject is specified
            %   either by its subject_id or its subject_name, implantNum
            %   denotes the number of the implant. In addition, hemisphere,
            %   brain area, and implant date need to be specified.
            
            if isnumeric(subject)
                key.subject_id = subject;
            else
                key.subject_id = fetch1(acq.Subjects & sprintf('subject_name = "%s"', subject), 'subject_id');
            end
            key.implant_num = implantNum;
            
            % couple of checks to make sure insert completes without errors
            assert(count(acq.Subjects & key) == 1, 'Subject not found!')
            assert(~count(ae.TetrodeImplants & key), 'Implant exists already!')
            assert(strcmpi(hemisphere, 'left') || strcmpi(hemisphere, 'right'), 'hemisphere must be either left or right!')
            assert(ischar(area) && length(area) <= 45, 'area must be a string of length <= 45!')
            assert(~isempty(regexpi(date, '^[0-9]{4}-[0-9]{2}-[0-9]{2}$', 'match')), ...
                'date must be a string of format yyyy-mm-dd!')

            tuple = key;
            tuple.hemisphere = hemisphere;
            tuple.area = area;
            tuple.implant_date = date;
            insert(ae.TetrodeImplants, tuple);
        end
    end
end
