extends CanvasLayer

onready var progress_bar_width = $ProgressBar.rect_size.x
onready var progress_bar_left = $ProgressBar.rect_position.x

onready var subs = get_parent().num_subs

func set_progress(progress):
	progress = clamp(progress, 0, 1)
	$ProgressMarker.position.x = progress_bar_left + progress_bar_width * progress

	if progress == 1 && !$EndText.visible:
		$EndText.visible = true
		$EndText.text = "Mines cleared! " + str(subs) + " / " + str(get_parent().num_subs) + " subs survived.\nClick anywhere to restart."
		
func sub_destroyed():
	subs -= 1
	
	if subs == 0:
		$EndText.visible = true
		$EndText.text = "All subs lost.\nClick anywhere to restart."
