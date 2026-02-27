<?php

namespace App\Models\campus_env;

use Illuminate\Database\Eloquent\Model;
use App\Models\User;

class CampusEnvTracking extends Model
{
    protected $table = 'campus_env_tracking';
    protected $primaryKey = 'cet_no';

    protected $fillable = [
        'cmp_env_com_no',
        'old_status',
        'new_status',
        'changed_by_user_id',
        'changed_date',
        'note',
    ];

    public function complaint()
    {
        return $this->belongsTo(CampusEnvComplaint::class, 'cmp_env_com_no', 'cmp_env_com_no');
    }

    public function changedBy()
    {
        return $this->belongsTo(User::class, 'changed_by_user_id', 'user_id');
    }
}
