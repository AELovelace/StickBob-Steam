if !variable_instance_exists(id, "sgcAmount") then sgcAmount = 1;
if !variable_instance_exists(id, "collectibleCode") then collectibleCode = "";

sgcAmount = floor(real(sgcAmount));
switch (sgcAmount) {
	case 1:
	case 3:
	case 5:
	case 10:
		break;
	default:
		sgcAmount = 1;
		break;
}

collectiblePulseSeed = irandom(1000000);
