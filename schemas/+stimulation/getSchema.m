function obj = getSchema
persistent schemaObject
if isempty(schemaObject)
    acq.getSchema();
    schemaObject = dj.Schema(dj.conn, 'stimulation', 'ecker2014_stimulation');
end
obj = schemaObject;
