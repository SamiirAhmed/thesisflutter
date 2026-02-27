<?php

namespace App\Models\campus_env;

use Illuminate\Database\Eloquent\Model;
use App\Models\User;

class CampusEnvAssign extends Model
{
    protected $table = 'campus_env_assign';
    protected $primaryKey = 'cea_no';

    protected $fillable = [
        'cmp_env_com_no',
        'assigned_to_user_id',
        'assigned_date',
        'assigned_status',
    ];

    public function complaint()
    {
        return $this->belongsTo(CampusEnvComplaint::class, 'cmp_env_com_no', 'cmp_env_com_no');
    }

    public function assignedUser()
    {
        return $this->belongsTo(User::class, 'assigned_to_user_id', 'user_id');
    }
}
