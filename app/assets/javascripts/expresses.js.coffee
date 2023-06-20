# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

$(document).on "turbolinks:load", ->
	ready()
	ini_clear()

ready = ->
	$('#batch_name').focus();
	$("#express_no").keypress(enterpress)
	$('#reset').click(clear)
	$("#return_save").click(enterpress2)
	$("#resend_express_no").keypress(enterpress3)

ini_clear = ->
	$('#batch_name').val("");
	$('#express_no').val("");
	$('#scaned_nos').val("");
	$('#htmls').val("");
	$('#num').val("");
	$('#out_results').html("");
	$('#resend_express_no').val("");
	$('#new_express_no').text("");
	$('#route_code').text("");
	$('#last_express_no').val("");
	$('#resend_out_results').html("");
	$('#batch_name').focus();
	$('#resend_express_no').focus();

clear = ->		
	$('#return_amount').text("");
	ini_clear()

enterpress = (e) ->
	e = e || window.event;   
	if e.keyCode == 13
		if ($('#express_no').val() != "")
			if ($('#scaned_nos').val() != "") && (Number($('#num').val()) > 50)
				alert("50个邮件已满，请保存"); 
			else
				if (isNaN($('#express_no').val())) || ($('#express_no').val().length != 13)
					alert("请输入13位纯数字");
				else
					if ($('#scaned_nos').val().search($('#express_no').val())!=-1)
						alert("不可重复扫描");
					else
						$('#num').val(Number($('#num').val())+1);
						$('#return_amount').text(Number($('#num').val()));
						if $('#scaned_nos').val() == ""
							$('#scaned_nos').val($('#express_no').val());
						else
							$('#scaned_nos').val($('#scaned_nos').val() + "," + $('#express_no').val());
							if (Number($('#num').val()) == 50)
								alert("50个邮件已满，请保存");
						htmls = "<table><tr style='color: green;'><td><h4>"+$('#express_no').val()+"</h4></td></tr></table>" + $('#htmls').val()
						$('#htmls').val(htmls);
						$('#out_results').html(htmls);
			$('#express_no').val("");
			$('#express_no').focus();
			return false;
		else
			if $('#batch_name').val() == ""
				alert("请录入堆名");
				$('#batch_name').focus();
				return false;
			else
				if confirm("是否保存？")
					if $('#scaned_nos').val() == ""
						alert("请扫描邮件");
						return false;
					else
						if Number($('#num').val()) <= 50
							return_save()
							clear()
							return false;

enterpress2 = ->
	if $('#batch_name').val() == ""
		alert("请录入堆名");
		$('#batch_name').focus();
		return false;
	else
		if confirm("是否保存？")
			if $('#scaned_nos').val() == ""
				alert("请扫描邮件");
				return false;
			else
				if Number($('#num').val()) <= 50
					return_save();
					clear();
					return false;
		else
			return false;

return_save = -> 
				$.ajax({
					type : 'POST',
					url : '../expresses/return_save/',
					data: { scaned_nos: $('#scaned_nos').val(), batch_name: $('#batch_name').val()},
					dataType : 'script'
				});

enterpress3 = (e) ->
	e = e || window.event;   
	if e.keyCode == 13
		if ($('#resend_express_no').val() != "")
			find_resend_express_result()
			return false;

find_resend_express_result = -> 
				$.ajax({
					type : 'POST',
					url : '../expresses/find_resend_express_result/',
					data: { resend_express_no: $('#resend_express_no').val()},
					dataType : 'script'
				});


showMask = ->
	document.getElementById('mid').style.display="block";
	#setTimeout("document.getElementById('mid').style.display='none';$('#resend_express_no').focus();",10000);