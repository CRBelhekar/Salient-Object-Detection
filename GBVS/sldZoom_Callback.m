% --- Executes on slider movement.
function sldZoom_Callback(hObject, eventdata, handles)
% hObject    handle to sldZoom (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
% 	scrollbarValue = get(hObject,'Value');
% 	caption = sprintf('H value = %.2f', scrollbarValue);
% 	set(handles.txtZoom, 'string', caption);
	try
		zoomFactor = get(hObject,'Value');
		axes(handles.axesImage);
		zoom('out');
		zoom(zoomFactor);
		txtInfo = sprintf('Zoom Factor = %.2f   (%d %%)\n\nOnce zoomed, you can pan by clicking and dragging in the image.', zoomFactor, round(zoomFactor * 100));
		set(handles.txtInfo, 'String', txtInfo);
		txtInfo = sprintf('Zoom Factor = %.2f\n\nOnce zoomed, you can pan by clicking and dragging in the image.', zoomFactor);
		set(handles.sldZoom, 'TooltipString', txtInfo);
		txtZoom = sprintf('Zoom Factor = %.2f   (%d %%)', zoomFactor, round(zoomFactor * 100));
		set(handles.txtZoom, 'String', txtZoom);
	% 	if zoomFactor ~= 1
	% 	else
	% 	end
		% Set up to allow panning of the image by clicking and dragging.
		% Cursor will show up as a little hand when it is over the image.
		set(handles.axesImage, 'ButtonDownFcn', 'disp(''This executes'')');
		set(handles.axesImage, 'Tag', 'DoNotIgnore');
		h = pan;
		set(h, 'ButtonDownFilter', @myPanCallbackFunction);
		set(h, 'Enable', 'on');
	catch ME
		message = sprintf('Error in sldZoom_Callback():\n%s', ME.message);
		msgboxw(message);
	end
	return; % from sldZoom_Callback