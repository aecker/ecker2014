function obj = getSchema
persistent schemaObject
if isempty(schemaObject)
    ephys.getSchema();
    schemaObject = dj.Schema(dj.conn, 'nc', 'ecker2014_nc');
end
obj = schemaObject;
