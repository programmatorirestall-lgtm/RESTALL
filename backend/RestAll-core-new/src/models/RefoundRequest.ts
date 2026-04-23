import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, UpdateDateColumn } from 'typeorm';

@Entity({ name: 'refound_request', schema: 'main' })
export class RefoundRequest {
  @PrimaryGeneratedColumn()
  id!: number;

  @Column()
  order_id!: number; // meglio number se l'ID WooCommerce è numerico

  @Column()
  amount!: number; // in centesimi

  @Column()
  reason!: string;

  @Column({ default: 'pending' })
  status!: 'pending' | 'approved' | 'declined' | 'refunded';

  @Column('json', { nullable: true })
  line_items!: { id: number; quantity: number }[];

  @CreateDateColumn({
    type: 'date',
    default: () => 'CURRENT_DATE',
  })
  created_at!: Date;

  @UpdateDateColumn({
    type: 'date',
    default: () => 'CURRENT_DATE',
    onUpdate: 'CURRENT_DATE',
  })
  updated_at!: Date;

  @Column()
  user_id!: string; // ID utente che ha richiesto il reso
}
